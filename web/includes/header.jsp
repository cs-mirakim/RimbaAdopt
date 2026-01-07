<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.UserDao" %>
<%@ page import="com.rimba.adopt.model.Users" %>
<%@ page import="java.sql.SQLException" %>

<%
    // Get session data
    String userName = SessionUtil.getUserName(request);
    String userRole = SessionUtil.getUserRole(request);
    String profilePhotoPath = SessionUtil.getProfilePhotoPath(request);

    // Format user role for display
    String displayRole = "";
    if ("admin".equals(userRole)) {
        displayRole = "Admin";
    } else if ("shelter".equals(userRole)) {
        displayRole = "Shelter";
    } else if ("adopter".equals(userRole)) {
        displayRole = "Adopter";
    }

    // Check if user has custom profile photo (not default)
    boolean hasCustomPhoto = profilePhotoPath != null
            && !profilePhotoPath.isEmpty()
            && !profilePhotoPath.contains("default.png");
%>

<header class="mb-1 bg-[#2F5D50] text-white flex items-center justify-between px-4 py-3 shadow-md w-full">
    <!-- Left: Sidebar button -->
    <button id="sidebarBtn" class="p-2 rounded hover:bg-[#24483E] transition-colors">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round"
                  d="M4 6h16M4 12h16M4 18h16"></path>
        </svg>
    </button>

    <!-- Center: Title -->
    <h1 class="text-lg font-semibold text-center flex-1">Rimba Adopt</h1>

    <!-- Right: Profile -->
    <% if (userName != null) {%>
    <div class="flex items-center gap-2 ml-auto">
        <!-- User info -->
        <div class="text-right hidden md:block">
            <div class="text-sm font-medium"><%= displayRole%></div>
            <div class="text-xs text-gray-300">Hi <%= userName%>!</div>
        </div>

        <!-- Profile link -->
        <a href="profile.jsp"
           class="flex items-center gap-2 px-3 py-2 rounded hover:bg-[#24483E] transition-colors">
            <% if (hasCustomPhoto) {%>
            <!-- Display profile picture if exists -->
            <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-200">
                <img src="<%= profilePhotoPath%>" 
                     alt="Profile" 
                     class="w-full h-full object-cover"
                     onerror="this.onerror=null; this.style.display='none'; this.parentElement.nextElementSibling.style.display='flex';">
            </div>
            <!-- Fallback letter avatar (hidden by default) -->
            <div class="w-8 h-8 bg-[#6DBF89] rounded-full items-center justify-center text-sm font-bold" style="display:none;">
                <%= userName.charAt(0)%>
            </div>
            <% } else {%>
            <!-- Default avatar with first letter -->
            <div class="w-8 h-8 bg-[#6DBF89] rounded-full flex items-center justify-center text-sm font-bold">
                <%= userName.charAt(0)%>
            </div>
            <% } %>
        </a>
    </div>
    <% } else { %>
    <!-- Not logged in - show login button -->
    <a href="login.jsp"
       class="flex items-center gap-2 px-3 py-2 rounded hover:bg-[#24483E] transition-colors ml-auto">
        <span class="text-sm font-medium">Login</span>
        <div class="w-8 h-8 bg-[#6DBF89] rounded-full flex items-center justify-center text-sm font-bold">
            L
        </div>
    </a>
    <% }%>
</header>