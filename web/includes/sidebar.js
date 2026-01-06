// includes/sidebar.js
// Script untuk handle semua logic sidebar - load sekali je untuk semua page

// Menu definitions untuk setiap role
const menus = {
    adopter: [
        {label: 'Dashboard', href: 'dashboard_adopter.jsp'},
        {label: 'Monitor Applications', href: 'monitor_application.jsp'},
        {label: 'Monitor Lost Animal', href: 'monitor_lost.jsp'},
        {label: 'Monitor Feedback', href: 'feedback_list.jsp'},
        {label: 'Pet List', href: 'pet_list.jsp'},
        {label: 'Shelter List', href: 'shelter_list.jsp'},
        {label: 'Lost Animal List', href: 'lost_animal.jsp'}
    ],
    shelter: [
        {label: 'Dashboard', href: 'dashboard_shelter.jsp'},
        {label: 'Manage Pets', href: 'manage_pets.jsp'},
        {label: 'Manage Requests', href: 'manage_request.jsp'}
    ],
    admin: [
        {label: 'Dashboard', href: 'dashboard_admin.jsp'},
        {label: 'Manage Banner', href: 'manage_banner.jsp'},
        {label: 'Review Registrations', href: 'review_registrations.jsp'}
    ]
};

// Function untuk initialize sidebar - akan dipanggil selepas HTML loaded
function initSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');
    const menuContainer = document.getElementById('sidebar-menu');
    const logoutBtn = document.getElementById('sidebar-logout-btn');
    const closeBtn = document.getElementById('sidebarClose');

    // Modal elements
    const logoutModal = document.getElementById('logout-modal');
    const logoutCancel = document.getElementById('logout-cancel');
    const logoutConfirm = document.getElementById('logout-confirm');

    if (!sidebar || !overlay || !menuContainer) {
        console.error('Sidebar elements not found');
        return;
    }

    // Function untuk show logout modal
    function showLogoutModal() {
        logoutModal.classList.remove('hidden');
        // Prevent body scrolling when modal is open
        document.body.style.overflow = 'hidden';
    }

    // Function untuk hide logout modal
    function hideLogoutModal() {
        logoutModal.classList.add('hidden');
        // Restore body scrolling
        document.body.style.overflow = '';
    }

    // Render menu untuk role tertentu
    function renderMenu(role) {
        menuContainer.innerHTML = '';
        const items = menus[role] || [];

        items.forEach((item, idx) => {
            let el;
            if (item.href) {
                // Anchor navigation untuk adopter pages
                el = document.createElement('a');
                el.href = item.href;
                el.setAttribute('role', 'menuitem');
                el.className = 'w-full block text-left px-3 py-2 rounded hover:bg-[#24483E] transition-colors';
                el.textContent = item.label;
            } else {
                // Fallback button yang call action
                el = document.createElement('button');
                el.type = 'button';
                el.className = 'w-full text-left px-3 py-2 rounded hover:bg-[#24483E] transition-colors';
                el.textContent = item.label;
                el.addEventListener('click', () => {
                    try {
                        item.action();
                    } catch (e) {
                        console.log(e);
                    }
                    closeSidebar();
                });
            }

            menuContainer.appendChild(el);

            // Divider line
            if (idx < items.length - 1) {
                const hr = document.createElement('div');
                hr.className = 'border-t border-slate-500/30 my-1';
                menuContainer.appendChild(hr);
            }
        });
    }

    // Open sidebar
    function openSidebar() {
        sidebar.classList.remove('-translate-x-full');
        overlay.classList.remove('hidden');
        sidebar.setAttribute('aria-hidden', 'false');
        overlay.setAttribute('aria-hidden', 'false');
    }

    // Close sidebar
    function closeSidebar() {
        sidebar.classList.add('-translate-x-full');
        overlay.classList.add('hidden');
        sidebar.setAttribute('aria-hidden', 'true');
        overlay.setAttribute('aria-hidden', 'true');
    }

    // Event delegation untuk header toggle button
    document.addEventListener('click', function (e) {
        const target = e.target;

        // Toggle sidebar bila click header button
        if (target.closest && target.closest('#sidebarBtn')) {
            if (sidebar.classList.contains('-translate-x-full'))
                openSidebar();
            else
                closeSidebar();
        }

        // Close bila click overlay
        if (target.closest && target.closest('#sidebar-overlay')) {
            closeSidebar();
        }
    });

    // Close button dalam sidebar
    if (closeBtn)
        closeBtn.addEventListener('click', closeSidebar);

    // Escape key tutup sidebar
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!logoutModal.classList.contains('hidden')) {
                hideLogoutModal();
            } else {
                closeSidebar();
            }
        }
    });

    // Radio change untuk tukar menu content
    document.addEventListener('change', (e) => {
        const r = e.target;
        if (r.name === 'sidebar_role') {
            renderMenu(r.value);
        }
    });

    // Logout button - show modal
    if (logoutBtn) {
        logoutBtn.addEventListener('click', (ev) => {
            ev.preventDefault();
            showLogoutModal();
        });
    }

    // Logout modal cancel button
    if (logoutCancel) {
        logoutCancel.addEventListener('click', (ev) => {
            ev.preventDefault();
            hideLogoutModal();
        });
    }

    // Logout modal confirm button - ensure sidebar closes
    if (logoutConfirm) {
        logoutConfirm.addEventListener('click', () => {
            closeSidebar();
            hideLogoutModal();
        });
    }

    // Click outside modal juga tutup modal
    if (logoutModal) {
        logoutModal.addEventListener('click', (ev) => {
            if (ev.target === logoutModal) {
                hideLogoutModal();
            }
        });
    }

    // Initial render (default checked radio)
    const initial = document.querySelector('input[name="sidebar_role"]:checked');
    renderMenu(initial ? initial.value : 'admin');

    // Overlay click juga tutup sidebar (tapi bukan modal)
    overlay.addEventListener('click', closeSidebar);
}

// ✅ PANGGIL initSidebar bila DOM ready
// Sekarang tak perlu fetch header/footer/sidebar sebab dah guna JSP include
document.addEventListener('DOMContentLoaded', function () {
    initSidebar();
});