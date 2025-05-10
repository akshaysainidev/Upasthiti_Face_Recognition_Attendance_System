from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import torch
from facenet_pytorch import MTCNN, InceptionResnetV1
from pymongo import MongoClient
from bson.binary import Binary
import pickle
from datetime import datetime
from typing import Dict, List, Optional
from bson import ObjectId
from pydantic import BaseModel, Field
import uuid

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB configuration
MONGODB_URI = "mongodb://localhost:27017/"
DATABASE_NAME = "attendance_system_v2"
client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Initialize models
device = 'cuda' if torch.cuda.is_available() else 'cpu'
mtcnn = MTCNN(image_size=160, margin=20, min_face_size=40, device=device, keep_all=True)
resnet = InceptionResnetV1(pretrained='vggface2').eval().to(device)

# Models with UUID fields
class School(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    address: str
    created_at: datetime = Field(default_factory=datetime.now)

class Course(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    school_id: str
    name: str
    duration_years: int
    created_at: datetime = Field(default_factory=datetime.now)

class Year(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    course_id: str
    year_name: str  #"1"
    sections: List[str] = []
    created_at: datetime = Field(default_factory=datetime.now)

class Section(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    year_id: str
    course_id:str
    name: str
    class_teacher: str
    created_at: datetime = Field(default_factory=datetime.now)

class Student(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    section_id: str
    section_name:str
    course_name:str
    course_id:str
    year: str
    year_id:str
    roll_no: str
    dob:str
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)

class AttendanceRecord(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    course_id:str
    year_id:str
    section_id:str
    subject_id:str
    subject: str
    date: str
    time: str
    attendance_students: List[str] = []  # List of student IDs ] -> ["13","14","53","10"]
    attendance_report: List[str] = []   # List of student attendance -> ["A","P","A","A"]
    created_at: datetime = Field(default_factory=datetime.now)


# Helper functions
def get_collection(name: str):
    return db[name]

def validate_references(ref_type: str, ref_id: str):
    """Validate that a reference ID exists in its collection"""
    collection_map = {
        'school': 'schools',
        'course': 'courses',
        'year': 'years',
        'section': 'sections',
        'student': 'students'
    }
    
    if ref_type not in collection_map:
        raise ValueError(f"Invalid reference type: {ref_type}")
    
    if not db[collection_map[ref_type]].find_one({"id": ref_id}):
        raise HTTPException(status_code=404, detail=f"{ref_type.capitalize()} not found")

# --------------------------
# School Endpoints
# --------------------------

@app.post("/schools/")
async def create_school(school: School):
    schools = get_collection("schools")
    
    if schools.find_one({"name": school.name}):
        raise HTTPException(status_code=400, detail="School with this name already exists")
    
    school_dict = school.dict()
    schools.insert_one(school_dict)
    
    return {
        "status": "success",
        "school_id": school.id,
        "message": f"School {school.name} created successfully"
    }

@app.get("/schools/")
async def list_schools():
    schools = list(get_collection("schools").find({}, {"_id": 0}))
    return {"status": "success", "schools": schools}

# --------------------------
# Course Endpoints
# --------------------------

@app.post("/courses/")
async def create_course(course: Course):
    courses = get_collection("courses")
    
    validate_references('school', course.school_id)
    
    if courses.find_one({"school_id": course.school_id, "name": course.name}):
        raise HTTPException(status_code=400, detail="Course with this name already exists in this school")
    
    course_dict = course.dict()
    courses.insert_one(course_dict)
    
    return {
        "status": "success", 
        "course_id": course.id,
        "message": f"Course {course.name} created successfully"
    }

@app.get("/schools/{school_id}/courses")
async def get_courses_by_school(school_id: str):
    validate_references('school', school_id)
    
    courses = list(get_collection("courses").find(
        {"school_id": school_id}, 
        {"_id": 0}
    ))
    return {"status": "success", "courses": courses}

# --------------------------
# Year Endpoints
# --------------------------

@app.post("/years/")
async def create_year(year: Year):
    years = get_collection("years")
    
    validate_references('course', year.course_id)
    
    if years.find_one({"course_id": year.course_id, "year_name": year.year_name}):
        raise HTTPException(status_code=400, detail="Year with this name already exists in this course")
    
    year_dict = year.dict()
    years.insert_one(year_dict)
    
    return {
        "status": "success",
        "year_id": year.id,
        "message": f"Year {year.year_name} created successfully"
    }

@app.get("/courses/{course_id}/years")
async def get_years_by_course(course_id: str):
    validate_references('course', course_id)
    
    years = list(get_collection("years").find(
        {"course_id": course_id}, 
        {"_id": 0}
    ))
    return {"status": "success", "years": years}

# --------------------------
# Section Endpoints
# --------------------------

@app.post("/sections/")
async def create_section(section: Section):
    sections = get_collection("sections")
    
    validate_references('year', section.year_id)
    validate_references('course', section.course_id)
    
    if sections.find_one({"year_id": section.year_id, "name": section.name}):
        raise HTTPException(status_code=400, detail="Section with this name already exists in this year")
    
    section_dict = section.dict()
    sections.insert_one(section_dict)
    
    return {
        "status": "success",
        "section_id": section.id,
        "message": f"Section {section.name} created successfully"
    }

@app.get("/years/{year_id}/sections")
async def get_sections_by_year(year_id: str):
    validate_references('year', year_id)
    
    sections = list(get_collection("sections").find(
        {"year_id": year_id}, 
        {"_id": 0}
    ))
    return {"status": "success", "sections": sections}

# --------------------------
# Student Endpoints
# --------------------------

@app.post("/students/")
async def register_student(
    student: Student,
    image: UploadFile = File(...)
):
    students = get_collection("students")
    
    validate_references('section', student.section_id)
    validate_references('course', student.course_id)
    validate_references('year', student.year_id)
    
    if students.find_one({"section_id": student.section_id, "roll_no": student.roll_no}):
        raise HTTPException(status_code=400, detail="Student with this roll number already exists in this section")
    
    # Process image and create embedding
    contents = await image.read()
    img = cv2.imdecode(np.frombuffer(contents, np.uint8), cv2.IMREAD_COLOR)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    faces = mtcnn(img)
    if faces is None:
        raise HTTPException(status_code=400, detail="No face detected in the image")
    
    embedding = resnet(faces[0].unsqueeze(0).to(device)).detach().cpu()
    
    # Create student record
    student_dict = student.dict()
    student_dict["embedding"] = Binary(pickle.dumps(embedding))
    
    # Store student
    students.insert_one(student_dict)
    
    # Store face image
    _, img_encoded = cv2.imencode('.jpg', cv2.cvtColor(img, cv2.COLOR_RGB2BGR))
    get_collection("face_images").insert_one({
        "student_id": student.id,
        "image": Binary(img_encoded.tobytes()),
        "created_at": datetime.now()
    })
    
    # Update embeddings mapping (using student_id instead of name)
    embeddings_col = get_collection("embeddings")
    embeddings_col.update_one(
        {"student_id": student.id},
        {"$set": {
            "student_id": student.id,
            "embedding": Binary(pickle.dumps(embedding)),
            "updated_at": datetime.now()
        }},
        upsert=True
    )
    
    return {
        "status": "success",
        "student_id": student.id,
        "message": f"Student {student.name} registered successfully"
    }

@app.get("/sections/{section_id}/students")
async def get_students_by_section(section_id: str):
    validate_references('section', section_id)
    
    students = list(get_collection("students").find(
        {"section_id": section_id},
        {"_id": 0, "embedding": 0}  # Exclude embedding for listing
    ))
    return {"status": "success", "students": students}

@app.get("/get_student_for_attendance")
async def get_student_for_attendance(course_id: str, year_id: str, section_id: str):
    validate_references('course', course_id)
    validate_references('year', year_id)
    validate_references('section', section_id)
    
    students = list(get_collection("students").find(
        {
            "course_id": course_id,
            "year_id": year_id,
            "section_id": section_id
        },
        {"_id": 0, "embedding": 0}  # Exclude sensitive/irrelevant fields
    ))
    
    if not students:
        raise HTTPException(status_code=404, detail="No students found for the given criteria")
    
    return {
        "status": "success",
        "count": len(students),
        "students": students
    }

# --------------------------
# Attendance Endpoints
# --------------------------

@app.get("/attendance/{section_id}")
async def get_attendance_by_section(section_id: str):
    validate_references('section', section_id)
    
    attendance_records = list(get_collection("attendance").find(
        {"section_id": section_id},
        {"_id": 0}
    ))
    return {"status": "success", "attendance_records": attendance_records}

# --------------------------
# Dummy Data Endpoints
# --------------------------

@app.post("/create_dummy_data/")
async def create_dummy_data():
    try:
        # Create a school
        school = School(
            name="Dummy University",
            address="123 Education St, Knowledge City"
        )
        school_dict = school.dict()
        db.schools.insert_one(school_dict)
        
        # Create a course
        course = Course(
            school_id=school.id,
            name="Bachelor of Technology",
            duration_years=4
        )
        course_dict = course.dict()
        db.courses.insert_one(course_dict)
        
        # Create a year
        year = Year(
            course_id=course.id,
            year_name="B.Tech(22-26)"
        )
        year_dict = year.dict()
        db.years.insert_one(year_dict)
        
        # Create a section
        section = Section(
            year_id=year.id,
            course_id=course.id,
            name="A",
            class_teacher="Dr. Smith"
        )
        section_dict = section.dict()
        db.sections.insert_one(section_dict)
        
        # Create some dummy students
        dummy_students = [
            {
                "section_id": section.id,
                "section_name": section.name,
                "course_name": course.name,
                "course_id": course.id,
                "year": 1,
                "year_id": year.id,
                "roll_no": "22BTCS001",
                "dob": "2000-01-01",
                "name": "John Doe",
                "email": "john@example.com",
                "phone": "1234567890"
            },
            {
                "section_id": section.id,
                "section_name": section.name,
                "course_name": course.name,
                "course_id": course.id,
                "year": 1,
                "year_id": year.id,
                "roll_no": "22BTCS002",
                "dob": "2000-02-02",
                "name": "Jane Smith",
                "email": "jane@example.com",
                "phone": "9876543210"
            }
        ]
        
        for student_data in dummy_students:
            student = Student(**student_data)
            db.students.insert_one(student.dict())
        
        return {
            "status": "success",
            "message": "Dummy data created successfully",
            "school_id": school.id,
            "course_id": course.id,
            "year_id": year.id,
            "section_id": section.id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Add this endpoint to your existing FastAPI code
@app.post("/register_student_with_face/")
async def register_student_with_face(
    name: str = Form(...),
    roll_no: str = Form(...),
    dob: str = Form(...),
    email: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    course_id: str = Form(...),
    year_id: str = Form(...),
    section_id: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        # Validate references
        validate_references('course', course_id)
        validate_references('year', year_id)
        validate_references('section', section_id)
        
        # Check if student already exists
        students = get_collection("students")
        if students.find_one({"section_id": section_id, "roll_no": roll_no}):
            raise HTTPException(status_code=400, detail="Student with this roll number already exists")
        
        # Process image and create embedding
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Detect face and get embedding
        faces = mtcnn(img)
        if faces is None:
            raise HTTPException(status_code=400, detail="No face detected in the image")
        
        embedding = resnet(faces[0].unsqueeze(0).to(device)).detach().cpu().numpy()
        embedding_list = embedding.flatten().tolist()
        
        # Get course and section details
        course = get_collection("courses").find_one({"id": course_id})
        year = get_collection("years").find_one({"id": year_id})
        section = get_collection("sections").find_one({"id": section_id})
        
        if not course or not year or not section:
            raise HTTPException(status_code=404, detail="Academic details not found")
        
        # Create student record
        student = Student(
            section_id=section_id,
            section_name=section["name"],
            course_name=course["name"],
            course_id=course_id,
            year=year["year_name"],
            year_id=year_id,
            roll_no=roll_no,
            dob=dob,
            name=name,
            email=email,
            phone=phone,
            address=address
        )
        student_dict = student.dict()
        student_dict["embedding"] = Binary(pickle.dumps(embedding_list))
        
        # Insert student
        students.insert_one(student_dict)
        
        # Store face image
        _, img_encoded = cv2.imencode('.jpg', cv2.cvtColor(img, cv2.COLOR_RGB2BGR))
        get_collection("face_images").insert_one({
            "student_id": student.id,
            "image": Binary(img_encoded.tobytes()),
            "created_at": datetime.now()
        })
        
        # Store embedding separately for efficient search
        get_collection("face_embeddings").insert_one({
            "student_id": student.id,
            "embedding": embedding_list,
            "created_at": datetime.now()
        })
        
        return {
            "status": "success",
            "student_id": student.id,
            "message": "Student registered successfully with face data"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="192.100.67.210", port=8000)
