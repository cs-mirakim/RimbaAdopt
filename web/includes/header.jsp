<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%
    String userName = SessionUtil.getUserName(session);
    String userRole = SessionUtil.getUserRole(session);
    String profilePhoto = SessionUtil.getUserProfilePhoto(session);

    // Default avatar
    String profileImgUrl = request.getContextPath() + "/assets/img/default-avatar.png";

    if (profilePhoto != null && !profilePhoto.isEmpty()) {
        profileImgUrl = request.getContextPath() + "/" + profilePhoto;
    }

    // Capitalize role
    String displayRole = userRole != null
            ? userRole.substring(0, 1).toUpperCase() + userRole.substring(1)
            : "User";
%>

<header class="bg-[#2F5D50] text-white flex items-center px-4 py-3 shadow-md w-full sticky top-0 z-40">

    <!-- Sidebar button -->
    <button id="sidebarBtn"
            class="p-2 rounded hover:bg-[#24483E] transition-colors mr-3">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2"
             viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round"
              d="M4 6h16M4 12h16M4 18h16"></path>
        </svg>
    </button>

    <!-- Title -->
    <h1 class="text-lg text-center font-semibold flex-1">
        Rimba Adopt
    </h1>

    <!-- Profile Area -->
    <a href="profile.jsp"
       class="flex items-center gap-3 px-3 py-2 rounded hover:bg-[#24483E] transition-colors">

        <div class="text-right leading-tight hidden sm:block">
            <p class="text-xs uppercase text-white/70"><%= displayRole%></p>
            <p class="text-sm font-medium">Hi, <%= userName%></p>
        </div>

        <img src="<%= profileImgUrl%>"
             alt="Profile"
             class="w-9 h-9 rounded-full object-cover border-2 border-white/30">
    </a>

</header>
