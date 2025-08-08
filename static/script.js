// API基础URL
const API_BASE = '/api';

// 全局状态
let currentImageIndex = 0;
let galleryImages = [];
let blogPosts = [];
let githubRepos = [];
let files = [];

// DOM元素
const elements = {
    // 导航
    mobileMenuBtn: document.getElementById('mobile-menu-btn'),
    mobileMenu: document.getElementById('mobile-menu'),
    
    // 博客
    blogPosts: document.getElementById('blog-posts'),
    newPostBtn: document.getElementById('new-post-btn'),
    newPostModal: document.getElementById('new-post-modal'),
    closePostModal: document.getElementById('close-post-modal'),
    cancelPost: document.getElementById('cancel-post'),
    newPostForm: document.getElementById('new-post-form'),
    
    // 图片
    imageCarousel: document.getElementById('image-carousel'),
    uploadImageBtn: document.getElementById('upload-image-btn'),
    uploadImageModal: document.getElementById('upload-image-modal'),
    closeImageModal: document.getElementById('close-image-modal'),
    cancelImage: document.getElementById('cancel-image'),
    uploadImageForm: document.getElementById('upload-image-form'),
    galleryPrev: document.getElementById('gallery-prev'),
    galleryNext: document.getElementById('gallery-next'),
    
    // 文件
    filesTable: document.getElementById('files-table'),
    uploadFileBtn: document.getElementById('upload-file-btn'),
    uploadFileModal: document.getElementById('upload-file-modal'),
    closeFileModal: document.getElementById('close-file-modal'),
    cancelFile: document.getElementById('cancel-file'),
    uploadFileForm: document.getElementById('upload-file-form'),
    
    // GitHub
    githubRepos: document.getElementById('github-repos'),
    
    // 留言
    commentForm: document.getElementById('comment-form'),
    commentsList: document.getElementById('comments-list')
};

// 工具函数
const utils = {
    // 显示通知
    showNotification(message, type = 'success') {
        const notification = document.createElement('div');
        notification.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-lg text-white ${
            type === 'success' ? 'bg-green-500' : 'bg-red-500'
        } shadow-lg transform transition-all duration-300`;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    },
    
    // 格式化日期
    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('zh-CN', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },
    
    // 截取文本
    truncateText(text, maxLength) {
        return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
    },
    
    // 获取文件图标
    getFileIcon(category, mimeType) {
        const icons = {
            image: 'fas fa-image text-green-500',
            document: 'fas fa-file-alt text-blue-500',
            code: 'fas fa-code text-purple-500',
            other: 'fas fa-file text-gray-500'
        };
        return icons[category] || icons.other;
    }
};

// API调用函数
const api = {
    async get(endpoint) {
        try {
            const response = await fetch(`${API_BASE}${endpoint}`);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('API GET error:', error);
            throw error;
        }
    },
    
    async post(endpoint, data) {
        try {
            const response = await fetch(`${API_BASE}${endpoint}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('API POST error:', error);
            throw error;
        }
    },
    
    async uploadFile(endpoint, formData) {
        try {
            const response = await fetch(`${API_BASE}${endpoint}`, {
                method: 'POST',
                body: formData
            });
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('API upload error:', error);
            throw error;
        }
    }
};

// 博客功能
const blog = {
    async loadPosts() {
        try {
            blogPosts = await api.get('/posts');
            this.renderPosts();
        } catch (error) {
            utils.showNotification('加载博客文章失败', 'error');
        }
    },
    
    renderPosts() {
        if (!elements.blogPosts) return;
        
        elements.blogPosts.innerHTML = blogPosts.map(post => `
            <article class="bg-white rounded-lg shadow-md overflow-hidden card-hover">
                <div class="p-6">
                    <div class="flex items-center justify-between mb-3">
                        <span class="text-sm text-purple-600 font-medium">${post.author}</span>
                        <span class="text-sm text-gray-500">${utils.formatDate(post.created_at)}</span>
                    </div>
                    <h3 class="text-xl font-semibold text-gray-800 mb-3">${post.title}</h3>
                    <p class="text-gray-600 mb-4">${utils.truncateText(post.content, 150)}</p>
                    <div class="flex items-center justify-between">
                        <div class="flex flex-wrap gap-2">
                            ${post.tags ? post.tags.split(',').map(tag => 
                                `<span class="bg-purple-100 text-purple-800 text-xs px-2 py-1 rounded-full">${tag.trim()}</span>`
                            ).join('') : ''}
                        </div>
                        <div class="flex items-center text-sm text-gray-500">
                            <i class="fas fa-comments mr-1"></i>
                            <span>${post.comment_count || 0}</span>
                        </div>
                    </div>
                    <button onclick="blog.viewPost(${post.id})" class="mt-4 text-purple-600 hover:text-purple-800 font-medium">
                        阅读全文 <i class="fas fa-arrow-right ml-1"></i>
                    </button>
                </div>
            </article>
        `).join('');
    },
    
    async viewPost(postId) {
        try {
            const post = await api.get(`/posts/${postId}`);
            const comments = await api.get(`/posts/${postId}/comments`);
            this.showPostModal(post, comments);
        } catch (error) {
            utils.showNotification('加载文章详情失败', 'error');
        }
    },
    
    showPostModal(post, comments) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
        modal.innerHTML = `
            <div class="bg-white rounded-lg max-w-4xl w-full max-h-screen overflow-y-auto">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-2xl font-bold text-gray-800">${post.title}</h2>
                        <button onclick="this.closest('.fixed').remove()" class="text-gray-400 hover:text-gray-600">
                            <i class="fas fa-times text-xl"></i>
                        </button>
                    </div>
                    <div class="flex items-center justify-between mb-6 text-sm text-gray-500">
                        <span>作者：${post.author}</span>
                        <span>${utils.formatDate(post.created_at)}</span>
                    </div>
                    <div class="prose max-w-none mb-8">
                        <p class="text-gray-700 leading-relaxed whitespace-pre-wrap">${post.content}</p>
                    </div>
                    ${post.tags ? `
                        <div class="flex flex-wrap gap-2 mb-8">
                            ${post.tags.split(',').map(tag => 
                                `<span class="bg-purple-100 text-purple-800 text-xs px-2 py-1 rounded-full">${tag.trim()}</span>`
                            ).join('')}
                        </div>
                    ` : ''}
                    <div class="border-t pt-6">
                        <h3 class="text-lg font-semibold mb-4">评论 (${comments.length})</h3>
                        <div class="space-y-4">
                            ${comments.map(comment => `
                                <div class="bg-gray-50 rounded-lg p-4">
                                    <div class="flex justify-between items-center mb-2">
                                        <span class="font-medium text-gray-800">${comment.name}</span>
                                        <span class="text-sm text-gray-500">${utils.formatDate(comment.created_at)}</span>
                                    </div>
                                    <p class="text-gray-700">${comment.content}</p>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
    },
    
    async createPost(postData) {
        try {
            await api.post('/posts', postData);
            utils.showNotification('文章发布成功');
            this.loadPosts();
            elements.newPostModal.classList.add('hidden');
            elements.newPostForm.reset();
        } catch (error) {
            utils.showNotification('发布文章失败', 'error');
        }
    }
};

// 图片展示功能
const gallery = {
    async loadImages() {
        try {
            galleryImages = await api.get('/gallery');
            this.renderImages();
        } catch (error) {
            utils.showNotification('加载图片失败', 'error');
        }
    },
    
    renderImages() {
        if (!elements.imageCarousel) return;
        
        elements.imageCarousel.innerHTML = galleryImages.map((image, index) => `
            <div class="flex-shrink-0 w-80 h-60 relative group cursor-pointer" onclick="gallery.showImageModal(${index})">
                <img src="${image.url}" alt="${image.description || image.original_name}" 
                     class="w-full h-full object-cover rounded-lg shadow-md group-hover:shadow-lg transition-shadow">
                <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all rounded-lg flex items-center justify-center">
                    <i class="fas fa-search-plus text-white text-2xl opacity-0 group-hover:opacity-100 transition-opacity"></i>
                </div>
                ${image.description ? `
                    <div class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-50 text-white p-2 rounded-b-lg">
                        <p class="text-sm truncate">${image.description}</p>
                    </div>
                ` : ''}
            </div>
        `).join('');
    },
    
    showImageModal(index) {
        const image = galleryImages[index];
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center p-4';
        modal.innerHTML = `
            <div class="relative max-w-4xl max-h-full">
                <button onclick="this.closest('.fixed').remove()" 
                        class="absolute top-4 right-4 text-white hover:text-gray-300 z-10">
                    <i class="fas fa-times text-2xl"></i>
                </button>
                <img src="${image.url}" alt="${image.description || image.original_name}" 
                     class="max-w-full max-h-full object-contain rounded-lg">
                ${image.description ? `
                    <div class="absolute bottom-4 left-4 right-4 bg-black bg-opacity-50 text-white p-3 rounded-lg">
                        <p>${image.description}</p>
                        <p class="text-sm text-gray-300 mt-1">上传时间：${utils.formatDate(image.uploaded_at)}</p>
                    </div>
                ` : ''}
            </div>
        `;
        document.body.appendChild(modal);
    },
    
    scrollCarousel(direction) {
        const carousel = elements.imageCarousel;
        const scrollAmount = 320; // 图片宽度 + 间距
        
        if (direction === 'next') {
            carousel.scrollLeft += scrollAmount;
        } else {
            carousel.scrollLeft -= scrollAmount;
        }
    },
    
    async uploadImage(formData) {
        try {
            await api.uploadFile('/upload/image', formData);
            utils.showNotification('图片上传成功');
            this.loadImages();
            elements.uploadImageModal.classList.add('hidden');
            elements.uploadImageForm.reset();
        } catch (error) {
            utils.showNotification('图片上传失败', 'error');
        }
    }
};

// 文件管理功能
const fileManager = {
    async loadFiles() {
        try {
            files = await api.get('/files');
            this.renderFiles();
        } catch (error) {
            utils.showNotification('加载文件列表失败', 'error');
        }
    },
    
    renderFiles() {
        if (!elements.filesTable) return;
        
        elements.filesTable.innerHTML = files.map(file => `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <i class="${utils.getFileIcon(file.category, file.mime_type)} mr-3"></i>
                        <span class="text-sm font-medium text-gray-900">${file.original_name}</span>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        file.category === 'image' ? 'bg-green-100 text-green-800' :
                        file.category === 'code' ? 'bg-purple-100 text-purple-800' :
                        file.category === 'document' ? 'bg-blue-100 text-blue-800' :
                        'bg-gray-100 text-gray-800'
                    }">
                        ${file.category}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    ${file.size_formatted}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    ${utils.formatDate(file.uploaded_at)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    ${file.download_count}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button onclick="fileManager.downloadFile(${file.id}, '${file.download_url}')" 
                            class="text-purple-600 hover:text-purple-900">
                        <i class="fas fa-download mr-1"></i>下载
                    </button>
                </td>
            </tr>
        `).join('');
    },
    
    async downloadFile(fileId, downloadUrl) {
        try {
            // 记录下载次数
            await api.post(`/files/${fileId}/download`, {});
            
            // 触发下载
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = '';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            // 刷新文件列表以更新下载次数
            this.loadFiles();
        } catch (error) {
            utils.showNotification('下载失败', 'error');
        }
    },
    
    async uploadFile(formData) {
        try {
            await api.uploadFile('/upload/file', formData);
            utils.showNotification('文件上传成功');
            this.loadFiles();
            elements.uploadFileModal.classList.add('hidden');
            elements.uploadFileForm.reset();
        } catch (error) {
            utils.showNotification('文件上传失败', 'error');
        }
    }
};

// GitHub项目展示
const github = {
    async loadRepos() {
        try {
            githubRepos = await api.get('/github/repos');
            this.renderRepos();
        } catch (error) {
            utils.showNotification('加载GitHub项目失败', 'error');
        }
    },
    
    renderRepos() {
        if (!elements.githubRepos) return;
        
        elements.githubRepos.innerHTML = githubRepos.map(repo => `
            <div class="bg-white rounded-lg shadow-md p-6 card-hover">
                <div class="flex items-start justify-between mb-4">
                    <h3 class="text-xl font-semibold text-gray-800">${repo.name}</h3>
                    <a href="${repo.html_url}" target="_blank" 
                       class="text-purple-600 hover:text-purple-800">
                        <i class="fab fa-github text-xl"></i>
                    </a>
                </div>
                <p class="text-gray-600 mb-4">${repo.description}</p>
                <div class="flex items-center justify-between text-sm text-gray-500">
                    <div class="flex items-center space-x-4">
                        <span class="flex items-center">
                            <i class="fas fa-circle text-${
                                repo.language === 'Python' ? 'blue' :
                                repo.language === 'JavaScript' ? 'yellow' :
                                'gray'
                            }-500 mr-1 text-xs"></i>
                            ${repo.language}
                        </span>
                        <span class="flex items-center">
                            <i class="fas fa-star mr-1"></i>
                            ${repo.stars}
                        </span>
                        <span class="flex items-center">
                            <i class="fas fa-code-branch mr-1"></i>
                            ${repo.forks}
                        </span>
                    </div>
                    <span>更新于 ${repo.updated_at}</span>
                </div>
            </div>
        `).join('');
    }
};

// 留言功能
const comments = {
    async loadComments() {
        try {
            // 加载所有留言（包括全站留言和文章评论）
            const allComments = await api.get('/comments');
            this.renderComments(allComments.slice(0, 8)); // 显示最新8条
        } catch (error) {
            utils.showNotification('加载留言失败', 'error');
        }
    },
    
    renderComments(commentsList) {
        if (!elements.commentsList) return;
        
        elements.commentsList.innerHTML = commentsList.map(comment => `
            <div class="bg-gray-50 rounded-lg p-4">
                <div class="flex justify-between items-center mb-2">
                    <span class="font-medium text-gray-800">${comment.name}</span>
                    <span class="text-sm text-gray-500">${utils.formatDate(comment.created_at)}</span>
                </div>
                <p class="text-gray-700">${comment.content}</p>
            </div>
        `).join('');
    },
    
    async submitComment(commentData) {
        try {
            await api.post('/comments', commentData);
            utils.showNotification('留言提交成功');
            elements.commentForm.reset();
            this.loadComments();
        } catch (error) {
            utils.showNotification('留言提交失败', 'error');
        }
    }
};

// 事件监听器
function setupEventListeners() {
    // 移动端菜单
    elements.mobileMenuBtn?.addEventListener('click', () => {
        elements.mobileMenu.classList.toggle('hidden');
    });
    
    // 平滑滚动
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({ behavior: 'smooth' });
                elements.mobileMenu?.classList.add('hidden');
            }
        });
    });
    
    // 博客相关事件
    elements.newPostBtn?.addEventListener('click', () => {
        elements.newPostModal.classList.remove('hidden');
    });
    
    elements.closePostModal?.addEventListener('click', () => {
        elements.newPostModal.classList.add('hidden');
    });
    
    elements.cancelPost?.addEventListener('click', () => {
        elements.newPostModal.classList.add('hidden');
    });
    
    elements.newPostForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        const postData = {
            title: formData.get('title') || document.getElementById('post-title').value,
            author: formData.get('author') || document.getElementById('post-author').value,
            content: formData.get('content') || document.getElementById('post-content').value,
            tags: formData.get('tags') || document.getElementById('post-tags').value
        };
        await blog.createPost(postData);
    });
    
    // 图片相关事件
    elements.uploadImageBtn?.addEventListener('click', () => {
        elements.uploadImageModal.classList.remove('hidden');
    });
    
    elements.closeImageModal?.addEventListener('click', () => {
        elements.uploadImageModal.classList.add('hidden');
    });
    
    elements.cancelImage?.addEventListener('click', () => {
        elements.uploadImageModal.classList.add('hidden');
    });
    
    elements.uploadImageForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData();
        const fileInput = document.getElementById('image-file');
        const descriptionInput = document.getElementById('image-description');
        
        formData.append('file', fileInput.files[0]);
        formData.append('description', descriptionInput.value);
        
        await gallery.uploadImage(formData);
    });
    
    elements.galleryPrev?.addEventListener('click', () => {
        gallery.scrollCarousel('prev');
    });
    
    elements.galleryNext?.addEventListener('click', () => {
        gallery.scrollCarousel('next');
    });
    
    // 文件相关事件
    elements.uploadFileBtn?.addEventListener('click', () => {
        elements.uploadFileModal.classList.remove('hidden');
    });
    
    elements.closeFileModal?.addEventListener('click', () => {
        elements.uploadFileModal.classList.add('hidden');
    });
    
    elements.cancelFile?.addEventListener('click', () => {
        elements.uploadFileModal.classList.add('hidden');
    });
    
    elements.uploadFileForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData();
        const fileInput = document.getElementById('upload-file-input');
        
        formData.append('file', fileInput.files[0]);
        
        await fileManager.uploadFile(formData);
    });
    
    // 留言表单事件
    elements.commentForm?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const commentData = {
            post_id: blogPosts.length > 0 ? blogPosts[0].id : null,
            name: document.getElementById('comment-name').value,
            email: document.getElementById('comment-email').value,
            content: document.getElementById('comment-content').value
        };
        await comments.submitComment(commentData);
    });
    
    // 模态框外部点击关闭
    document.addEventListener('click', (e) => {
        if (e.target.classList.contains('fixed') && e.target.classList.contains('bg-black')) {
            e.target.classList.add('hidden');
        }
    });
}

// 初始化应用
async function initApp() {
    setupEventListeners();
    
    // 加载所有数据
    await Promise.all([
        blog.loadPosts(),
        gallery.loadImages(),
        fileManager.loadFiles(),
        github.loadRepos()
    ]);
    
    // 加载留言（需要等博客加载完成）
    await comments.loadComments();
    
    console.log('应用初始化完成');
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', initApp);

// 导出给全局使用
window.blog = blog;
window.gallery = gallery;
window.fileManager = fileManager;