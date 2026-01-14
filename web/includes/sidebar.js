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

    // Get user role from data attribute
    const userRole = menuContainer.getAttribute('data-user-role') || 'adopter';

    console.log('Current user role:', userRole);

    // Function untuk show logout modal
    function showLogoutModal() {
        logoutModal.classList.remove('hidden');

        // Check if page actually has scrollbar
        const hasScrollbar = document.body.scrollHeight > window.innerHeight;

        if (hasScrollbar) {
            // Only add padding if page has scrollbar
            const scrollbarWidth = getScrollbarWidth();
            document.body.style.paddingRight = scrollbarWidth + 'px';
        }

        // Prevent body scrolling when modal is open
        document.body.style.overflow = 'hidden';
    }

    // Function untuk hide logout modal
    function hideLogoutModal() {
        logoutModal.classList.add('hidden');
        // Restore body scrolling
        document.body.style.overflow = '';
        document.body.style.paddingRight = '';
    }

    // Get scrollbar width to prevent layout shift
    function getScrollbarWidth() {
        const outer = document.createElement('div');
        outer.style.visibility = 'hidden';
        outer.style.overflow = 'scroll';
        document.body.appendChild(outer);
        const inner = document.createElement('div');
        outer.appendChild(inner);
        const scrollbarWidth = outer.offsetWidth - inner.offsetWidth;
        outer.parentNode.removeChild(outer);
        return scrollbarWidth;
    }

    // Render menu untuk role tertentu
    function renderMenu(role) {
        menuContainer.innerHTML = '';
        const items = menus[role] || [];

        if (items.length === 0) {
            const noItems = document.createElement('p');
            noItems.className = 'text-white/50 text-sm text-center py-4';
            noItems.textContent = 'No menu items available';
            menuContainer.appendChild(noItems);
            return;
        }

        items.forEach((item, idx) => {
            let el;
            if (item.href) {
                // Anchor navigation
                el = document.createElement('a');
                el.href = item.href;
                el.setAttribute('role', 'menuitem');
                el.className = 'w-full flex items-center justify-between px-4 py-3 rounded-lg hover:bg-[#24483E] transition-all duration-200 group';

                // Text container
                const textSpan = document.createElement('span');
                textSpan.textContent = item.label;
                textSpan.className = 'text-sm font-medium';
                el.appendChild(textSpan);

                // Arrow icon
                const arrowSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
                arrowSvg.setAttribute('class', 'w-4 h-4 text-white/60 group-hover:text-white group-hover:translate-x-1 transition-all duration-200');
                arrowSvg.setAttribute('fill', 'none');
                arrowSvg.setAttribute('stroke', 'currentColor');
                arrowSvg.setAttribute('stroke-width', '2');
                arrowSvg.setAttribute('viewBox', '0 0 24 24');
                const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
                path.setAttribute('stroke-linecap', 'round');
                path.setAttribute('stroke-linejoin', 'round');
                path.setAttribute('d', 'M9 5l7 7-7 7');
                arrowSvg.appendChild(path);
                el.appendChild(arrowSvg);

                // Highlight current page
                const currentPath = window.location.pathname.split('/').pop() || '';
                if (item.href.includes(currentPath)) {
                    el.className += ' bg-[#24483E] border-l-4 border-[#6DBF89]';
                }
            } else {
                // Fallback button yang call action
                el = document.createElement('button');
                el.type = 'button';
                el.className = 'w-full flex items-center justify-between px-4 py-3 rounded-lg hover:bg-[#24483E] transition-all duration-200 group';

                const textSpan = document.createElement('span');
                textSpan.textContent = item.label;
                textSpan.className = 'text-sm font-medium';
                el.appendChild(textSpan);

                // Arrow icon
                const arrowSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
                arrowSvg.setAttribute('class', 'w-4 h-4 text-white/60 group-hover:text-white group-hover:translate-x-1 transition-all duration-200');
                arrowSvg.setAttribute('fill', 'none');
                arrowSvg.setAttribute('stroke', 'currentColor');
                arrowSvg.setAttribute('stroke-width', '2');
                arrowSvg.setAttribute('viewBox', '0 0 24 24');
                const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
                path.setAttribute('stroke-linecap', 'round');
                path.setAttribute('stroke-linejoin', 'round');
                path.setAttribute('d', 'M9 5l7 7-7 7');
                arrowSvg.appendChild(path);
                el.appendChild(arrowSvg);

                if (item.action) {
                    el.addEventListener('click', () => {
                        try {
                            item.action();
                        } catch (e) {
                            console.log(e);
                        }
                        closeSidebar();
                    });
                }
            }

            menuContainer.appendChild(el);

            // Divider line - IMPROVED (lebih jelas dan terang)
            const hr = document.createElement('div');
            hr.className = 'border-t border-[#6DBF89]/40 my-2';
            menuContainer.appendChild(hr);
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
            if (logoutModal && !logoutModal.classList.contains('hidden')) {
                hideLogoutModal();
            } else {
                closeSidebar();
            }
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

    // Logout modal confirm button
    if (logoutConfirm) {
        logoutConfirm.addEventListener('click', () => {
            closeSidebar();
            hideLogoutModal();
            // Redirect handled by href
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

    // Initial render berdasarkan role user
    renderMenu(userRole);

    // Overlay click tutup sidebar
    overlay.addEventListener('click', closeSidebar);
}

// ✅ PANGGIL initSidebar bila DOM ready
document.addEventListener('DOMContentLoaded', function () {
    initSidebar();
});