from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import mysql.connector
import os
import json
import uuid
import shutil
from datetime import datetime

app = FastAPI(title="个人站点API", description="支持博客、图片展示、文件管理和留言功能的个人站点")

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 数据库配置
DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "11.142.154.110"),
    "port": int(os.getenv("MYSQL_PORT", 3306)),
    "database": os.getenv("MYSQL_DATABASE", "9901v1pi"),
    "user": os.getenv("MYSQL_USERNAME", "with_tutxxymqpvytugnb"),
    "password": os.getenv("MYSQL_PASSWORD", "xB*5KkJYIs*1NI")
}

# 创建上传目录
os.makedirs("static/uploads/images", exist_ok=True)
os.makedirs("static/uploads/files", exist_ok=True)

def get_db_connection():
    """获取数据库连接"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except mysql.connector.Error as err:
        raise HTTPException(status_code=500, detail=f"数据库连接失败: {err}")

# Pydantic模型
class BlogPost(BaseModel):
    title: str
    content: str
    author: str
    tags: Optional[str] = ""

class Comment(BaseModel):
    post_id: Optional[int] = None
    name: str
    email: Optional[str] = ""
    content: str

class BlogPostResponse(BaseModel):
    id: int
    title: str
    content: str
    author: str
    created_at: str
    tags: Optional[str] = ""
    comment_count: int = 0

class CommentResponse(BaseModel):
    id: int
    post_id: Optional[int]
    name: str
    content: str
    created_at: str

# 博客相关API
@app.get("/api/posts", response_model=List[BlogPostResponse])
async def get_posts():
    """获取所有博客文章"""
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # 获取文章及评论数量
        query = """
        SELECT p.*, COUNT(c.id) as comment_count
        FROM blog_posts p
        LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'approved'
        WHERE p.status = 'published'
        GROUP BY p.id
        ORDER BY p.created_at DESC
        """
        cursor.execute(query)
        posts = cursor.fetchall()
        
        for post in posts:
            post['created_at'] = post['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return posts
    finally:
        cursor.close()
        connection.close()

@app.get("/api/posts/{post_id}", response_model=BlogPostResponse)
async def get_post(post_id: int):
    """获取单篇博客文章"""
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        query = """
        SELECT p.*, COUNT(c.id) as comment_count
        FROM blog_posts p
        LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'approved'
        WHERE p.id = %s AND p.status = 'published'
        GROUP BY p.id
        """
        cursor.execute(query, (post_id,))
        post = cursor.fetchone()
        
        if not post:
            raise HTTPException(status_code=404, detail="文章不存在")
        
        post['created_at'] = post['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        return post
    finally:
        cursor.close()
        connection.close()

@app.post("/api/posts")
async def create_post(post: BlogPost):
    """创建新博客文章"""
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        query = """
        INSERT INTO blog_posts (title, content, author, tags)
        VALUES (%s, %s, %s, %s)
        """
        cursor.execute(query, (post.title, post.content, post.author, post.tags))
        connection.commit()
        
        return {"message": "文章创建成功", "id": cursor.lastrowid}
    finally:
        cursor.close()
        connection.close()

# 评论相关API
@app.get("/api/posts/{post_id}/comments", response_model=List[CommentResponse])
async def get_comments(post_id: int):
    """获取文章评论"""
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        query = """
        SELECT * FROM comments
        WHERE post_id = %s AND status = 'approved'
        ORDER BY created_at ASC
        """
        cursor.execute(query, (post_id,))
        comments = cursor.fetchall()
        
        for comment in comments:
            comment['created_at'] = comment['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return comments
    finally:
        cursor.close()
        connection.close()

@app.post("/api/comments")
async def create_comment(comment: Comment):
    """创建新评论"""
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        query = """
        INSERT INTO comments (post_id, name, email, content, status)
        VALUES (%s, %s, %s, %s, 'approved')
        """
        cursor.execute(query, (comment.post_id, comment.name, comment.email, comment.content))
        connection.commit()
        
        return {"message": "评论提交成功"}
    finally:
        cursor.close()
        connection.close()

# 图片上传和展示API
@app.post("/api/upload/image")
async def upload_image(file: UploadFile = File(...), description: str = Form("")):
    """上传图片"""
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="只能上传图片文件")
    
    # 生成唯一文件名
    file_extension = file.filename.split('.')[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"static/uploads/images/{unique_filename}"
    
    # 保存文件
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # 保存到数据库
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        query = """
        INSERT INTO gallery_images (filename, original_name, file_path, file_size, mime_type, description)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            unique_filename, file.filename, file_path,
            file.size, file.content_type, description
        ))
        connection.commit()
        
        return {"message": "图片上传成功", "filename": unique_filename, "path": f"/uploads/images/{unique_filename}"}
    finally:
        cursor.close()
        connection.close()

@app.get("/api/gallery")
async def get_gallery():
    """获取图片库"""
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        query = """
        SELECT id, filename, original_name, description, uploaded_at,
               CONCAT('/uploads/images/', filename) as url
        FROM gallery_images
        WHERE is_active = TRUE
        ORDER BY uploaded_at DESC
        """
        cursor.execute(query)
        images = cursor.fetchall()
        
        for image in images:
            image['uploaded_at'] = image['uploaded_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return images
    finally:
        cursor.close()
        connection.close()

# 文件上传和管理API
@app.post("/api/upload/file")
async def upload_file(file: UploadFile = File(...)):
    """上传文件"""
    # 生成唯一文件名
    file_extension = file.filename.split('.')[-1] if '.' in file.filename else ''
    unique_filename = f"{uuid.uuid4()}.{file_extension}" if file_extension else str(uuid.uuid4())
    file_path = f"static/uploads/files/{unique_filename}"
    
    # 保存文件
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # 确定文件类别
    category = "other"
    if file.content_type:
        if file.content_type.startswith('image/'):
            category = "image"
        elif file.content_type.startswith('text/') or file.filename.endswith(('.py', '.js', '.html', '.css', '.json')):
            category = "code"
        elif file.content_type.startswith('application/'):
            category = "document"
    
    # 保存到数据库
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        query = """
        INSERT INTO file_uploads (filename, original_name, file_path, file_size, mime_type, category)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            unique_filename, file.filename, file_path,
            file.size, file.content_type, category
        ))
        connection.commit()
        
        return {"message": "文件上传成功", "filename": unique_filename, "path": f"/uploads/files/{unique_filename}"}
    finally:
        cursor.close()
        connection.close()

@app.get("/api/files")
async def get_files():
    """获取文件列表"""
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        query = """
        SELECT id, filename, original_name, file_size, mime_type, category, uploaded_at, download_count,
               CONCAT('/uploads/files/', filename) as download_url
        FROM file_uploads
        WHERE is_public = TRUE
        ORDER BY uploaded_at DESC
        """
        cursor.execute(query)
        files = cursor.fetchall()
        
        for file in files:
            file['uploaded_at'] = file['uploaded_at'].strftime('%Y-%m-%d %H:%M:%S')
            # 格式化文件大小
            size = file['file_size'] or 0
            if size < 1024:
                file['size_formatted'] = f"{size} B"
            elif size < 1024 * 1024:
                file['size_formatted'] = f"{size / 1024:.1f} KB"
            else:
                file['size_formatted'] = f"{size / (1024 * 1024):.1f} MB"
        
        return files
    finally:
        cursor.close()
        connection.close()

@app.post("/api/files/{file_id}/download")
async def track_download(file_id: int):
    """记录文件下载次数"""
    connection = get_db_connection()
    cursor = connection.cursor()
    
    try:
        query = "UPDATE file_uploads SET download_count = download_count + 1 WHERE id = %s"
        cursor.execute(query, (file_id,))
        connection.commit()
        
        return {"message": "下载记录成功"}
    finally:
        cursor.close()
        connection.close()

# GitHub项目展示API（模拟数据）
@app.get("/api/github/repos")
async def get_github_repos():
    """获取GitHub项目列表（模拟数据）"""
    repos = [
        {
            "id": 1,
            "name": "personal-website",
            "description": "个人网站项目，包含博客、图片展示、文件管理等功能",
            "language": "Python",
            "stars": 15,
            "forks": 3,
            "updated_at": "2024-01-15",
            "html_url": "https://github.com/username/personal-website"
        },
        {
            "id": 2,
            "name": "fastapi-blog",
            "description": "基于FastAPI的博客系统",
            "language": "Python",
            "stars": 28,
            "forks": 7,
            "updated_at": "2024-01-10",
            "html_url": "https://github.com/username/fastapi-blog"
        },
        {
            "id": 3,
            "name": "vue-admin-dashboard",
            "description": "Vue.js管理后台模板",
            "language": "JavaScript",
            "stars": 42,
            "forks": 12,
            "updated_at": "2024-01-08",
            "html_url": "https://github.com/username/vue-admin-dashboard"
        },
        {
            "id": 4,
            "name": "python-utils",
            "description": "Python实用工具集合",
            "language": "Python",
            "stars": 8,
            "forks": 2,
            "updated_at": "2024-01-05",
            "html_url": "https://github.com/username/python-utils"
        }
    ]
    return repos

# 挂载静态文件
app.mount("/uploads", StaticFiles(directory="static/uploads"), name="uploads")
app.mount("/static", StaticFiles(directory="static", html=True), name="static")