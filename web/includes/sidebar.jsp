<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%
    String userRole = SessionUtil.getUserRole(session);
    String userName = SessionUtil.getUserName(session);

    // Determine which menu to show
    String currentRole = userRole != null ? userRole : "adopter"; // default
%>

<div id="sidebar-overlay" class="fixed inset-0 bg-black bg-opacity-30 backdrop-blur-sm hidden z-40" aria-hidden="true"></div>

<aside id="sidebar"
       class="fixed left-0 top-0 h-full w-64 bg-[#2F5D50] text-white transform -translate-x-full transition-transform duration-300 z-50 shadow-lg"
       aria-hidden="true" aria-label="Sidebar">
    <!-- Top: Brand + User Info -->
    <div class="p-6 border-b border-[#24483E]/50">
        <div class="flex items-center justify-between mb-4">
            <div class="flex-1">
                <div class="text-xl font-bold tracking-wide">Rimba Adopt</div>
                <% if (userName != null) {%>
                <div class="text-sm text-white/80 mt-2 font-medium">Hi, <%= userName%></div>
                <% } %>
            </div>
            <!-- close small x for when sidebar visible on small screens -->
            <button id="sidebarClose" class="p-1.5 rounded hover:bg-[#24483E] transition-colors ml-2" 
                    title="Close sidebar" aria-label="Close sidebar">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>

        <!-- User Role Display - More Attractive -->
        <% if (userRole != null) {
                String displayRole = userRole.substring(0, 1).toUpperCase() + userRole.substring(1);
        %>
        <div class="mt-3 inline-flex items-center gap-2 bg-[#6DBF89] px-4 py-2 rounded-lg shadow-sm">
            <svg class="w-4 h-4 text-[#2B2B2B]" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
            </svg>
            <span class="text-sm font-semibold text-[#2B2B2B]"><%= displayRole%> Account</span>
        </div>
        <% }%>
    </div>

    <!-- Menu container (akan di-populate oleh sidebar.js) -->
    <!-- Data attribute untuk pass role ke JavaScript -->
    <nav id="sidebar-menu" 
         data-user-role="<%= currentRole%>"
         class="flex flex-col p-4 gap-0 overflow-y-auto" 
         style="max-height: calc(100vh - 250px);"
         aria-label="Sidebar navigation">
        <!-- JS akan inject menu items sini -->
    </nav>

    <!-- Logout at bottom -->
    <div class="absolute bottom-0 w-full p-4 border-t border-[#24483E]/50 bg-[#2F5D50]">
        <button id="sidebar-logout-btn"
                class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-[#C49A6C] text-white font-semibold hover:bg-[#B88A5C] transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#C49A6C] shadow-md hover:shadow-lg"
                title="Logout" aria-label="Logout">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
            </svg>
            <span>Logout</span>
        </button>
    </div>
</aside>

<!-- Logout Confirmation Modal (with scroll fix) -->
<div id="logout-modal" class="fixed inset-0 z-[60] hidden">
    <div class="fixed inset-0 bg-black/40 backdrop-blur-sm"></div>
    <div class="fixed inset-0 flex items-center justify-center p-4 overflow-y-auto">
        <div class="bg-white rounded-lg shadow-xl w-full max-w-md overflow-hidden my-8">
            <div class="p-5 border-b border-gray-200">
                <h3 class="text-lg font-semibold text-gray-900">Confirm Logout</h3>
            </div>
            <div class="p-5">
                <p class="text-gray-700">Are you sure you want to logout from Rimba Adopt?</p>
            </div>
            <div class="p-5 border-t border-gray-200 flex justify-end gap-3">
                <button id="logout-cancel" 
                        type="button"
                        class="px-5 py-2.5 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
                    Cancel
                </button>
                <a href="AuthServlet?action=logout"
                   id="logout-confirm"
                   class="px-5 py-2.5 text-sm font-medium text-white bg-[#C49A6C] hover:bg-[#B88A5C] rounded-lg transition-colors">
                    Logout
                </a>
            </div>
        </div>
    </div>
</div>