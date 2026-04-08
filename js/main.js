// ============================================
// 装修不踩坑 - 全站脚本
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    initNavbar();
    initBackToTop();
    loadMarkdownContent();
});

// --- 导航栏 ---
function initNavbar() {
    const toggle = document.getElementById('navToggle');
    const menu = document.getElementById('navMenu');

    if (toggle && menu) {
        toggle.addEventListener('click', () => {
            menu.classList.toggle('active');
        });

        // 点击链接后关闭菜单
        menu.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', () => {
                menu.classList.remove('active');
            });
        });
    }

    // 滚动效果
    window.addEventListener('scroll', () => {
        const navbar = document.getElementById('navbar');
        if (navbar) {
            navbar.classList.toggle('scrolled', window.scrollY > 20);
        }
    });
}

// --- 回到顶部 ---
function initBackToTop() {
    const btn = document.createElement('button');
    btn.className = 'back-to-top';
    btn.innerHTML = '↑';
    btn.setAttribute('aria-label', '回到顶部');
    document.body.appendChild(btn);

    window.addEventListener('scroll', () => {
        btn.classList.toggle('visible', window.scrollY > 400);
    });

    btn.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
}

// --- Markdown 内容加载 ---
function loadMarkdownContent() {
    const mdContainer = document.getElementById('md-content');
    if (!mdContainer) return;

    const mdFile = mdContainer.getAttribute('data-md');
    if (!mdFile) return;

    mdContainer.innerHTML = '<div class="loading">加载中</div>';

    fetch(mdFile)
        .then(res => {
            if (!res.ok) throw new Error('文件未找到');
            return res.text();
        })
        .then(text => {
            mdContainer.innerHTML = marked.parse(text);
        })
        .catch(() => {
            mdContainer.innerHTML = '<p style="color: var(--gray-400); text-align: center;">内容即将更新，敬请期待...</p>';
        });
}
