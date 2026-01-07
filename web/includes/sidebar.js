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
    console.log('Initializing sidebar...');

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

    // Function untuk detect user role dari multiple sources
    function getUserRole() {
        // Method 1: dari data attribute pada body
        const bodyRole = document.body.getAttribute('data-user-role');
        if (bodyRole) {
            console.log('Got user role from body data attribute:', bodyRole);
            return bodyRole;
        }

        // Method 2: dari hidden input
        const hiddenInput = document.getElementById('user-role-data');
        if (hiddenInput && hiddenInput.value) {
            console.log('Got user role from hidden input:', hiddenInput.value);
            return hiddenInput.value;
        }

        // Method 3: dari current URL (fallback)
        const currentPath = window.location.pathname;
        if (currentPath.includes('dashboard_admin')) {
            console.log('Detected admin from URL');
            return 'admin';
        } else if (currentPath.includes('dashboard_shelter')) {
            console.log('Detected shelter from URL');
            return 'shelter';
        } else if (currentPath.includes('dashboard_adopter')) {
            console.log('Detected adopter from URL');
            return 'adopter';
        }

        // Default fallback
        console.log('Using default role: admin');
        return 'admin';
    }

    // Render menu berdasarkan user role
    function renderMenu() {
        const userRole = getUserRole();
        console.log('Rendering menu for role:', userRole);

        menuContainer.innerHTML = '';
        const items = menus[userRole] || [];

        if (items.length === 0) {
            console.warn('No menu items found for role:', userRole);
            const noItems = document.createElement('div');
            noItems.className = 'text-center text-gray-400 py-4';
            noItems.textContent = 'No menu items available';
            menuContainer.appendChild(noItems);
            return;
        }

        items.forEach((item, idx) => {
            let el;
            if (item.href) {
                // Anchor navigation untuk pages
                el = document.createElement('a');
                el.href = item.href;
                el.setAttribute('role', 'menuitem');
                el.className = 'w-full block text-left px-3 py-2 rounded hover:bg-[#24483E] transition-colors focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white';
                el.textContent = item.label;

                // Highlight current page
                if (window.location.pathname.includes(item.href.replace('.jsp', ''))) {
                    el.className += ' bg-[#24483E]';
                }
            } else {
                // Fallback button yang call action
                el = document.createElement('button');
                el.type = 'button';
                el.className = 'w-full text-left px-3 py-2 rounded hover:bg-[#24483E] transition-colors focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white';
                el.textContent = item.label;
                el.addEventListener('click', () => {
                    try {
                        item.action();
                    } catch (e) {
                        console.log('Menu action error:', e);
                    }
                    closeSidebar();
                });
            }

            menuContainer.appendChild(el);

            // Divider line (kecuali untuk item terakhir)
            if (idx < items.length - 1) {
                const hr = document.createElement('div');
                hr.className = 'border-t border-slate-500/30 my-1';
                menuContainer.appendChild(hr);
            }
        });

        console.log('Menu rendered with', items.length, 'items for role:', userRole);
    }

    // Open sidebar
    function openSidebar() {
        sidebar.classList.remove('-translate-x-full');
        overlay.classList.remove('hidden');
        sidebar.setAttribute('aria-hidden', 'false');
        overlay.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden'; // Prevent body scrolling
    }

    // Close sidebar
    function closeSidebar() {
        sidebar.classList.add('-translate-x-full');
        overlay.classList.add('hidden');
        sidebar.setAttribute('aria-hidden', 'true');
        overlay.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = ''; // Restore body scrolling
    }

    // Event delegation untuk header toggle button
    document.addEventListener('click', function (e) {
        const target = e.target;
        const sidebarBtn = document.getElementById('sidebarBtn');

        // Toggle sidebar bila click header button
        if (target === sidebarBtn || (sidebarBtn && sidebarBtn.contains(target))) {
            if (sidebar.classList.contains('-translate-x-full')) {
                openSidebar();
            } else {
                closeSidebar();
            }
            e.preventDefault();
        }

        // Close bila click overlay
        if (target === overlay || (overlay && overlay.contains(target))) {
            closeSidebar();
        }
    });

    // Close button dalam sidebar
    if (closeBtn) {
        closeBtn.addEventListener('click', (e) => {
            e.preventDefault();
            closeSidebar();
        });
    }

    // Escape key tutup sidebar
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!logoutModal.classList.contains('hidden')) {
                hideLogoutModal();
            } else if (!sidebar.classList.contains('-translate-x-full')) {
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
        logoutConfirm.addEventListener('click', (e) => {
            e.preventDefault();
            console.log('Logging out...');
            closeSidebar();
            hideLogoutModal();
            // Redirect to logout servlet
            window.location.href = 'logout';
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

    // Initial render berdasarkan user role
    renderMenu();

    // Re-render menu jika ada perubahan pada role (optional)
    const observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            if (mutation.type === 'attributes' &&
                    (mutation.attributeName === 'data-user-role' ||
                            mutation.target.id === 'user-role-data')) {
                console.log('Role changed, re-rendering menu');
                renderMenu();
            }
        });
    });

    // Observe body for role changes
    observer.observe(document.body, {attributes: true});

    // Observe hidden input for role changes
    const roleInput = document.getElementById('user-role-data');
    if (roleInput) {
        observer.observe(roleInput, {attributes: true});
    }

    console.log('Sidebar initialized successfully');
}

// ✅ PANGGIL initSidebar bila DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSidebar);
} else {
    // DOM sudah ready
    initSidebar();
}