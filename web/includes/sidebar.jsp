<!-- includes/sidebar.html -->
<!-- Sidebar + overlay - HTML sahaja, TIADA script -->
<div id="sidebar-overlay" class="fixed inset-0 bg-black bg-opacity-30 backdrop-blur-sm hidden z-40" aria-hidden="true"></div>

<aside id="sidebar"
       class="fixed left-0 top-0 h-full w-64 bg-[#2F5D50] text-white transform -translate-x-full transition-transform duration-300 z-50 shadow-lg"
       aria-hidden="true" aria-label="Sidebar">
    <!-- Top: Brand + Account Type switcher -->
    <div class="p-4 border-b border-[#24483E]">
        <div class="flex items-center justify-between mb-3">
            <div class="text-lg font-semibold">Rimba Adopt</div>
            <!-- close small x for when sidebar visible on small screens -->
            <button id="sidebarClose" class="p-1 rounded hover:bg-[#24483E] transition-colors" title="Close sidebar" aria-label="Close sidebar">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>

        <!-- Account Type radio (storyboard switcher) -->
        <fieldset class="mb-2">
            <legend class="block mb-2 text-sm font-medium text-white/90">Account Type</legend>
            <div class="flex gap-2">
                <label class="inline-flex items-center gap-2 cursor-pointer text-sm">
                    <input type="radio" name="sidebar_role" value="admin" checked class="cursor-pointer accent-[#6DBF89]"/>
                    <span>Admin</span>
                </label>
                <label class="inline-flex items-center gap-2 cursor-pointer text-sm">
                    <input type="radio" name="sidebar_role" value="shelter" class="cursor-pointer accent-[#6DBF89]"/>
                    <span>Shelter</span>
                </label>
                <label class="inline-flex items-center gap-2 cursor-pointer text-sm">
                    <input type="radio" name="sidebar_role" value="adopter" class="cursor-pointer accent-[#6DBF89]"/>
                    <span>Adopter</span>
                </label>
            </div>
        </fieldset>
    </div>

    <!-- Menu container (akan di-populate oleh sidebar.js) -->
    <nav id="sidebar-menu" class="flex flex-col p-4 gap-2" aria-label="Sidebar navigation">
        <!-- JS akan inject menu items sini -->
    </nav>

    <!-- Logout at bottom -->
    <div class="absolute bottom-0 w-full p-4 border-t border-[#24483E]">
        <button id="sidebar-logout-btn"
                class="w-full inline-flex items-center justify-center px-3 py-2 rounded bg-[#B84A4A] text-white font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#B84A4A]"
                title="Logout" aria-label="Logout">
            Logout
        </button>
    </div>
</aside>

<!-- Logout Confirmation Modal -->
<div id="logout-modal" class="fixed inset-0 z-[60] hidden">
    <!-- Background overlay (blur effect, di atas sidebar overlay) -->
    <div class="fixed inset-0 bg-black/40 backdrop-blur-sm"></div>

    <!-- Modal content -->
    <div class="fixed inset-0 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg shadow-xl w-full max-w-md overflow-hidden">
            <!-- Modal header -->
            <div class="p-4 border-b border-gray-200">
                <h3 class="text-lg font-semibold text-gray-900">Confirm Logout</h3>
            </div>

            <!-- Modal body -->
            <div class="p-4">
                <p class="text-gray-700">Are you sure you want to logout from Rimba Adopt?</p>
            </div>

            <!-- Modal footer -->
            <div class="p-4 border-t border-gray-200 flex justify-end gap-3">
                <button id="logout-cancel" 
                        type="button"
                        class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors">
                    Cancel
                </button>
                <a href="login.html"
                   id="logout-confirm"
                   class="px-4 py-2 text-sm font-medium text-white bg-[#B84A4A] hover:bg-red-700 rounded-md transition-colors">
                    Logout
                </a>
            </div>
        </div>
    </div>
</div>