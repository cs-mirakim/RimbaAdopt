<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.model.Users" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="com.rimba.adopt.model.Adopter" %>
<%@ page import="java.util.Map" %>

<%
    // Check if user is logged in
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Get data from request attributes (set by ProfileServlet)
    Map<String, Object> profileData = (Map<String, Object>) request.getAttribute("profileData");
    String userRole = (String) request.getAttribute("userRole");

    // Fallback to session if attributes not set
    if (profileData == null) {
        response.sendRedirect("ProfileServlet");
        return;
    }

    Users user = (Users) profileData.get("user");
    Shelter shelter = (Shelter) profileData.get("shelter");
    Adopter adopter = (Adopter) profileData.get("adopter");
    Map<String, String> adminInfo = (Map<String, String>) profileData.get("admin");

    // Error/Success messages
    String errorMessage = (String) request.getAttribute("errorMessage");
    String successMessage = (String) request.getAttribute("successMessage");

    // Profile photo URL
    String profileImgUrl = request.getContextPath() + "/assets/img/default-avatar.png";
    if (user.getProfilePhotoPath() != null && !user.getProfilePhotoPath().isEmpty()) {
        profileImgUrl = request.getContextPath() + "/" + user.getProfilePhotoPath();
    }

    // Capitalize role for display
    String displayRole = userRole != null
            ? userRole.substring(0, 1).toUpperCase() + userRole.substring(1)
            : "User";
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <script src="https://cdn.tailwindcss.com"></script>
        <title>Profile Page</title>

        <style>
            .inner-scroll::-webkit-scrollbar { width: 8px; }
            .inner-scroll::-webkit-scrollbar-thumb { background: rgba(43,43,43,0.12); border-radius: 6px; }
            html, body { height: 100%; }
        </style>
    </head>
    <body class="bg-[#F6F3E7] min-h-screen flex flex-col">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- MAIN: centered, footer-safe -->
        <main class="flex-1 flex items-center justify-center p-6">
            <div class="w-full max-w-7xl bg-white py-6 rounded-xl shadow-md mx-auto flex flex-col md:flex-row"
                 style="max-height: calc(100vh - 180px); overflow: hidden;">

                <!-- LEFT PANEL: CENTERED -->
                <aside class="w-full md:w-80 px-6 py-6 border-b md:border-b-0 md:border-r border-[#E5E5E5] flex flex-col items-center gap-6">

                    <!-- role display (NO RADIO BUTTONS) -->
                    <div class="w-full flex flex-col items-center gap-2">
                        <label class="block text-sm font-medium text-[#2B2B2B] mb-1 text-center">Account Type</label>
                        <div class="flex gap-2">
                            <span class="px-3 py-1 rounded text-sm font-medium
                                  <%= "admin".equals(userRole) ? "bg-[#C49A6C] text-white" : "bg-[#A8E6CF] text-[#2B2B2B]"%>">
                                <%= displayRole%>
                            </span>
                        </div>
                    </div>

                    <!-- avatar + name + badge -->
                    <div class="mt-4 flex flex-col items-center w-full gap-2">
                        <div class="w-28 h-28 rounded-full overflow-hidden border-4 border-[#E5E5E5]">
                            <img src="<%= profileImgUrl%>" 
                                 alt="<%= user.getName()%>'s profile picture"
                                 class="w-full h-full object-cover"
                                 onerror="this.onerror=null; this.src='<%= request.getContextPath()%>/assets/img/default-avatar.png'">
                        </div>
                        <h1 id="profile-name" class="text-xl md:text-2xl font-bold text-[#2B2B2B]">
                            <%= user.getName()%>
                        </h1>
                        <span class="inline-block mt-1 text-xs px-3 py-1 rounded 
                              <%= "admin".equals(userRole) ? "bg-[#C49A6C] text-white" : "bg-[#A8E6CF] text-[#2B2B2B]"%>
                              font-medium">
                            <%= userRole != null ? userRole.toUpperCase() : "USER"%>
                        </span>
                    </div>

                    <!-- action buttons -->
                    <div class="w-full max-w-[160px] flex flex-col items-center mt-4 gap-2">
                        <button id="btn-edit" 
                                class="w-40 px-4 py-2 bg-[#2F5D50] text-white rounded hover:bg-[#24483E] transition-colors font-medium">
                            Edit Profile
                        </button>
                        <button id="btn-delete"
                                class="w-full max-w-[160px] px-4 py-2 bg-[#B84A4A] text-white rounded hover:bg-[#8B3A3A] transition-colors font-medium">
                            Delete Account
                        </button>
                    </div>

                </aside>

                <!-- RIGHT PANEL: scrollable details -->
                <section class="flex-1 px-6 py-6 inner-scroll" style="overflow-y: auto; max-height: calc(100% - 0px);">

                    <!-- Error/Success Messages -->
                    <% if (errorMessage != null && !errorMessage.isEmpty()) {%>
                    <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
                        <p class="text-red-600 text-sm"><%= errorMessage%></p>
                    </div>
                    <% } %>

                    <% if (successMessage != null && !successMessage.isEmpty()) {%>
                    <div class="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
                        <p class="text-green-600 text-sm"><%= successMessage%></p>
                    </div>
                    <% } %>

                    <div id="profile-content">
                        <% if ("adopter".equals(userRole) && adopter != null) {%>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">Personal Information</h3>
                                <%= renderField("Email", user.getEmail())%>
                                <%= renderField("Phone", user.getPhone())%>
                                <%= renderField("Address", adopter.getAddress())%>
                                <%= renderField("Occupation", adopter.getOccupation())%>
                            </div>
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">Household Details</h3>
                                <%= renderField("Household Type", adopter.getHouseholdType())%>
                                <%= renderField("Has Other Pets", adopter.getHasOtherPets() == 1 ? "Yes" : "No")%>
                                <%= renderField("Notes", adopter.getNotes(), true)%>
                            </div>
                        </div>
                        <% } else if ("shelter".equals(userRole) && shelter != null) {%>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">Contact Information</h3>
                                <%= renderField("Email", user.getEmail())%>
                                <%= renderField("Phone", user.getPhone())%>
                                <%= renderLinkField("Website", shelter.getWebsite())%>
                            </div>
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">Shelter Details</h3>
                                <%= renderField("Shelter Name", shelter.getShelterName())%>
                                <%= renderField("Operating Hours", shelter.getOperatingHours())%>
                                <%= renderStatusBadge("Approval Status", shelter.getApprovalStatus())%>
                            </div>
                            <div class="md:col-span-2 space-y-4">
                                <%= renderField("Shelter Address", shelter.getShelterAddress())%>
                                <%= renderField("Description", shelter.getShelterDescription(), true)%>
                            </div>
                        </div>
                        <% } else if ("admin".equals(userRole)) {%>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">Administrator Information</h3>
                                <%= renderField("Email", user.getEmail())%>
                                <%= renderField("Phone", user.getPhone())%>
                                <%= renderField("Position", adminInfo != null ? adminInfo.get("position") : "Administrator")%>
                            </div>
                            <div class="space-y-4">
                                <h3 class="text-lg font-semibold text-[#2F5D50] mb-3 border-b border-[#E5E5E5] pb-2">System Access</h3>
                                <div class="bg-[#F6F3E7] p-4 rounded-lg">
                                    <p class="text-sm text-[#2B2B2B] mb-2">Administrator privileges enabled</p>
                                    <div class="flex gap-2 flex-wrap">
                                        <span class="text-xs px-2 py-1 rounded bg-[#A8E6CF] text-[#2B2B2B]">User Management</span>
                                        <span class="text-xs px-2 py-1 rounded bg-[#A8E6CF] text-[#2B2B2B]">Site Settings</span>
                                        <span class="text-xs px-2 py-1 rounded bg-[#A8E6CF] text-[#2B2B2B]">Content Moderation</span>
                                        <span class="text-xs px-2 py-1 rounded bg-[#A8E6CF] text-[#2B2B2B]">Shelter Approval</span>
                                        <span class="text-xs px-2 py-1 rounded bg-[#A8E6CF] text-[#2B2B2B]">Banner Management</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <% }%>
                    </div>
                </section>
            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Edit Profile Modal -->
        <div id="edit-modal" class="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm hidden z-50 flex items-center justify-center p-4">
            <div class="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
                <div class="sticky top-0 bg-white border-b border-[#E5E5E5] px-6 py-4 flex items-center justify-between">
                    <h2 class="text-xl font-bold text-[#2B2B2B]">Edit Profile</h2>
                    <button id="close-edit-modal" class="p-2 rounded hover:bg-[#F6F3E7] transition-colors">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>
                <form id="edit-form" class="p-6" action="ProfileServlet" method="POST" enctype="multipart/form-data">
                    <input type="hidden" name="action" value="update">

                    <!-- Form content akan diisi oleh JavaScript -->
                    <div id="form-content" class="text-center py-8">
                        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-[#2F5D50] mx-auto"></div>
                        <p class="text-gray-500 mt-2">Loading form...</p>
                    </div>
                </form>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div id="delete-modal" class="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm hidden z-50 flex items-center justify-center p-4">
            <div class="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
                <div class="text-center mb-6">
                    <div class="w-16 h-16 bg-[#B84A4A] rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                        </svg>
                    </div>
                    <h2 class="text-xl font-bold text-[#2B2B2B] mb-2">Delete Account?</h2>
                    <p class="text-[#2B2B2B] opacity-75">Are you sure you want to delete your account? This action cannot be undone.</p>
                </div>
                <div class="flex gap-3">
                    <button type="button" id="close-delete-modal"
                            class="flex-1 px-4 py-2 bg-[#E5E5E5] text-[#2B2B2B] rounded hover:bg-[#D5D5D5] transition-colors font-medium">
                        Cancel
                    </button>
                    <!-- FORM DALAM DIV YANG SAMA DENGAN BUTTON CANCEL -->
                    <form action="ProfileServlet" method="POST" class="flex-1">
                        <input type="hidden" name="action" value="delete">
                        <button type="submit" 
                                class="w-full px-4 py-2 bg-[#B84A4A] text-white rounded hover:bg-[#8B3A3A] transition-colors font-medium">
                            Delete
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- Success Alert (Hidden by default) -->
        <div id="success-alert" class="fixed top-20 right-6 bg-[#6DBF89] text-[#06321F] px-6 py-3 rounded-lg shadow-lg hidden z-50 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"></path>
            </svg>
            <span id="alert-message">Profile updated successfully!</span>
        </div>

        <!-- JSP Helper Functions -->
        <%!
            private String renderField(String label, String value) {
                return renderField(label, value, false, false);
            }

            private String renderField(String label, String value, boolean isTextarea) {
                return renderField(label, value, isTextarea, false);
            }

            private String renderField(String label, String value, boolean isTextarea, boolean isLink) {
                if (value == null) {
                    value = "";
                }

                if (isLink && !value.isEmpty() && !value.startsWith("http")) {
                    value = "https://" + value;
                }

                String html = "<div><label class=\"block text-sm font-medium text-[#2B2B2B] mb-1\">" + label + "</label>";

                if (isLink && !value.isEmpty()) {
                    html += "<a href=\"" + value + "\" target=\"_blank\" class=\"text-[#2F5D50] hover:text-[#24483E] underline break-all\">" + value + "</a>";
                } else if (isTextarea) {
                    html += "<p class=\"text-[#2B2B2B] whitespace-pre-wrap\">" + value.replace("\n", "<br>") + "</p>";
                } else {
                    html += "<p class=\"text-[#2B2B2B]\">" + (value.isEmpty() ? "Not provided" : value) + "</p>";
                }

                html += "</div>";
                return html;
            }

            private String renderLinkField(String label, String value) {
                return renderField(label, value, false, true);
            }

            private String renderStatusBadge(String label, String status) {
                if (status == null) {
                    status = "";
                }

                String colorClass;
                String statusLower = status.toLowerCase();

                // Tukar dari switch ke if-else untuk Java 5 compatibility
                if ("approved".equals(statusLower)) {
                    colorClass = "bg-[#6DBF89] text-[#06321F]";
                } else if ("pending".equals(statusLower)) {
                    colorClass = "bg-[#C49A6C] text-white";
                } else if ("rejected".equals(statusLower)) {
                    colorClass = "bg-[#B84A4A] text-white";
                } else {
                    colorClass = "bg-gray-200 text-gray-700";
                }

                return "<div><label class=\"block text-sm font-medium text-[#2B2B2B] mb-1\">" + label + "</label>"
                        + "<span class=\"inline-block px-3 py-1 rounded text-sm font-medium " + colorClass + "\">"
                        + status.toUpperCase() + "</span></div>";
            }
        %>

        <script>
            // User data from JSP (SEPERTI LAMA)
            let currentUserData = {
                role: '<%= userRole%>',
                name: '<%= user.getName() != null ? user.getName().replace("'", "\\'") : ""%>',
                email: '<%= user.getEmail() != null ? user.getEmail().replace("'", "\\'") : ""%>',
                phone: '<%= user.getPhone() != null ? user.getPhone().replace("'", "\\'") : ""%>',
                profilePhotoPath: '<%= user.getProfilePhotoPath() != null ? user.getProfilePhotoPath().replace("'", "\\'") : ""%>'
            };

            <% if ("shelter".equals(userRole) && shelter != null) {%>
            currentUserData.shelter = {
                shelterName: '<%= shelter.getShelterName() != null ? shelter.getShelterName().replace("'", "\\'") : ""%>',
                shelterAddress: '<%= shelter.getShelterAddress() != null ? shelter.getShelterAddress().replace("'", "\\'") : ""%>',
                shelterDescription: '<%= shelter.getShelterDescription() != null ? shelter.getShelterDescription().replace("'", "\\'") : ""%>',
                website: '<%= shelter.getWebsite() != null ? shelter.getWebsite().replace("'", "\\'") : ""%>',
                operatingHours: '<%= shelter.getOperatingHours() != null ? shelter.getOperatingHours().replace("'", "\\'") : ""%>'
            };
            <% } else if ("adopter".equals(userRole) && adopter != null) {%>
            currentUserData.adopter = {
                address: '<%= adopter.getAddress() != null ? adopter.getAddress().replace("'", "\\'") : ""%>',
                occupation: '<%= adopter.getOccupation() != null ? adopter.getOccupation().replace("'", "\\'") : ""%>',
                householdType: '<%= adopter.getHouseholdType() != null ? adopter.getHouseholdType().replace("'", "\\'") : ""%>',
                hasOtherPets: <%= adopter.getHasOtherPets() != null ? adopter.getHasOtherPets() : 0%>,
                notes: '<%= adopter.getNotes() != null ? adopter.getNotes().replace("'", "\\'") : ""%>'
            };
            <% } else if ("admin".equals(userRole) && adminInfo != null) {%>
            currentUserData.admin = {
                position: '<%= adminInfo.get("position") != null ? adminInfo.get("position").replace("'", "\\'") : ""%>'
            };
            <% }%>

            let selectedFile = null;

            // Modal elements (STRUKTUR BARU)
            const editModal = document.getElementById('edit-modal');
            const deleteModal = document.getElementById('delete-modal');
            const btnEdit = document.getElementById('btn-edit');
            const btnDelete = document.getElementById('btn-delete');
            const closeEditBtn = document.getElementById('close-edit-modal');
            const closeDeleteBtn = document.getElementById('close-delete-modal');

            // Event listeners (STRUKTUR BARU)
            if (btnEdit) {
                btnEdit.addEventListener('click', openEditModal);
            }

            if (btnDelete) {
                btnDelete.addEventListener('click', openDeleteModal);
            }

            if (closeEditBtn) {
                closeEditBtn.addEventListener('click', closeEditModal);
            }

            if (closeDeleteBtn) {
                closeDeleteBtn.addEventListener('click', closeDeleteModal);
            }

            // Close modals on backdrop click
            if (editModal) {
                editModal.addEventListener('click', function (e) {
                    if (e.target === editModal) {
                        closeEditModal();
                    }
                });
            }

            if (deleteModal) {
                deleteModal.addEventListener('click', function (e) {
                    if (e.target === deleteModal) {
                        closeDeleteModal();
                    }
                });
            }

            // ESC key to close modals
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') {
                    if (!editModal.classList.contains('hidden')) {
                        closeEditModal();
                    }
                    if (!deleteModal.classList.contains('hidden')) {
                        closeDeleteModal();
                    }
                }
            });

            // Get scrollbar width to prevent layout shift (SEPERTI LAMA)
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

            // Function to open edit modal (KOMBINASI LAMA + BARU)
            function openEditModal() {
                populateEditForm();
                const modal = document.getElementById('edit-modal');
                modal.classList.remove('hidden');

                // Check if page has scrollbar (SEPERTI LAMA)
                const hasScrollbar = document.body.scrollHeight > window.innerHeight;
                if (hasScrollbar) {
                    const scrollbarWidth = getScrollbarWidth();
                    document.body.style.paddingRight = scrollbarWidth + 'px';
                }
                document.body.style.overflow = 'hidden';
            }

            // Function to close edit modal (KOMBINASI LAMA + BARU)
            function closeEditModal() {
                const modal = document.getElementById('edit-modal');
                modal.classList.add('hidden');
                document.body.style.overflow = '';
                document.body.style.paddingRight = '';
                selectedFile = null;
            }

            // Function to open delete modal (KOMBINASI LAMA + BARU)
            function openDeleteModal() {
                const modal = document.getElementById('delete-modal');
                modal.classList.remove('hidden');

                // Check if page has scrollbar (SEPERTI LAMA)
                const hasScrollbar = document.body.scrollHeight > window.innerHeight;
                if (hasScrollbar) {
                    const scrollbarWidth = getScrollbarWidth();
                    document.body.style.paddingRight = scrollbarWidth + 'px';
                }
                document.body.style.overflow = 'hidden';
            }

            // Function to close delete modal (KOMBINASI LAMA + BARU)
            function closeDeleteModal() {
                const modal = document.getElementById('delete-modal');
                modal.classList.add('hidden');
                document.body.style.overflow = '';
                document.body.style.paddingRight = '';
            }

            // Populate edit form (SEPERTI LAMA)
            function populateEditForm() {
                const formContent = document.getElementById('form-content');
                const role = currentUserData.role;

                let formHTML = '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
                        '<div>' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Name *</label>' +
                        '<input type="text" name="name" value="' + (currentUserData.name || '') + '" required ' +
                        'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                        '</div>' +
                        '<div>' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Email *</label>' +
                        '<input type="email" name="email" value="' + (currentUserData.email || '') + '" required ' +
                        'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                        '</div>' +
                        '<div>' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Phone</label>' +
                        '<input type="tel" name="phone" value="' + (currentUserData.phone || '') + '" ' +
                        'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                        '</div>';

                // Profile Photo Upload (SEPERTI LAMA)
                formHTML += '<div class="md:col-span-2">' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Profile Photo</label>' +
                        '<div class="flex items-start gap-4">' +
                        '<div class="relative w-24 h-24 border-2 border-dashed border-gray-300 rounded-full overflow-hidden bg-gray-50 flex items-center justify-center group cursor-pointer hover:border-[#2F5D50] transition-colors" onclick="document.getElementById(\'edit-profile-photo\').click()">' +
                        '<img id="edit-profile-preview" src="' + (currentUserData.profilePhotoPath ? '<%= request.getContextPath()%>/' + currentUserData.profilePhotoPath : '<%= request.getContextPath()%>/assets/img/default-avatar.png') + '" alt="" class="w-full h-full object-cover">' +
                        '<div id="edit-upload-placeholder" class="hidden text-center p-3">' +
                        '<svg class="w-6 h-6 mx-auto text-gray-400 group-hover:text-[#2F5D50]" fill="none" stroke="currentColor" viewBox="0 0 24 24">' +
                        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>' +
                        '</svg>' +
                        '<p class="text-xs text-gray-500 group-hover:text-[#2F5D50] mt-1">Upload</p>' +
                        '</div>' +
                        '</div>' +
                        '<div class="flex-1">' +
                        '<p class="text-sm text-gray-600 mb-2">Upload a new profile photo (optional)</p>' +
                        '<div class="space-y-1">' +
                        '<input type="file" id="edit-profile-photo" name="profile_photo" accept="image/*" class="hidden" onchange="previewEditImage(event)">' +
                        '<button type="button" onclick="document.getElementById(\'edit-profile-photo\').click()"' +
                        'class="px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 rounded-md transition-colors">' +
                        'Choose Image' +
                        '</button>' +
                        '<p class="text-xs text-gray-500">Max 2MB • JPG, PNG, GIF</p>' +
                        '<p id="edit-image-error" class="text-xs text-red-500 hidden"></p>' +
                        '</div>' +
                        '</div>' +
                        '</div>' +
                        '</div>';

                // Change Password Checkbox (SEPERTI LAMA)
                formHTML += '<div class="md:col-span-2 mt-4">' +
                        '<div class="flex items-center gap-2">' +
                        '<input id="change-password-check" name="change_password" type="checkbox" value="on" class="h-4 w-4 text-[#2F5D50] focus:ring-[#2F5D50] border-gray-300 rounded" onclick="togglePasswordFields()">' +
                        '<label for="change-password-check" class="text-sm cursor-pointer">Change Password</label>' +
                        '</div>' +
                        '<div id="password-fields" class="hidden mt-3 grid grid-cols-1 md:grid-cols-2 gap-4">' +
                        '<div>' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">New Password</label>' +
                        '<input type="password" name="new_password" class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                        '</div>' +
                        '<div>' +
                        '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Confirm Password</label>' +
                        '<input type="password" name="confirm_password" class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                        '</div>' +
                        '</div>' +
                        '</div>';

                // Role-specific fields (SEPERTI LAMA)
                if (role === 'adopter' && currentUserData.adopter) {
                    formHTML += '<div class="md:col-span-2 mt-4 pt-4 border-t border-[#E5E5E5]">' +
                            '<h3 class="text-sm font-medium text-[#2B2B2B] mb-3">Adopter Details</h3>' +
                            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Address *</label>' +
                            '<input type="text" name="address" value="' + (currentUserData.adopter.address || '') + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '</div>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Occupation *</label>' +
                            '<input type="text" name="occupation" value="' + (currentUserData.adopter.occupation || '') + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '</div>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Household Type *</label>' +
                            '<select name="household_type" required class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '<option value="">Select household type</option>' +
                            '<option value="apartment" ' + (currentUserData.adopter.householdType === 'apartment' ? 'selected' : '') + '>Apartment/Condo</option>' +
                            '<option value="terrace" ' + (currentUserData.adopter.householdType === 'terrace' ? 'selected' : '') + '>Terrace House</option>' +
                            '<option value="semi_d" ' + (currentUserData.adopter.householdType === 'semi_d' ? 'selected' : '') + '>Semi-Detached</option>' +
                            '<option value="bungalow" ' + (currentUserData.adopter.householdType === 'bungalow' ? 'selected' : '') + '>Bungalow</option>' +
                            '<option value="other" ' + (!['apartment', 'terrace', 'semi_d', 'bungalow'].includes(currentUserData.adopter.householdType) && currentUserData.adopter.householdType ? 'selected' : '') + '>Other</option>' +
                            '</select>' +
                            '</div>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Has Other Pets</label>' +
                            '<div class="flex items-center gap-2">' +
                            '<input type="checkbox" name="has_other_pets" value="on" ' + (currentUserData.adopter.hasOtherPets == 1 ? 'checked' : '') + ' class="h-4 w-4 text-[#2F5D50] focus:ring-[#2F5D50] border-gray-300 rounded">' +
                            '<span class="text-sm">I currently have other pets</span>' +
                            '</div>' +
                            '</div>' +
                            '<div class="md:col-span-2">' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Additional Notes</label>' +
                            '<textarea name="notes" rows="3" class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' + (currentUserData.adopter.notes || '') + '</textarea>' +
                            '</div>' +
                            '</div>' +
                            '</div>';

                } else if (role === 'shelter' && currentUserData.shelter) {
                    // Parse operating hours
                    let hoursFrom = '09:00';
                    let hoursTo = '17:00';
                    if (currentUserData.shelter.operatingHours && currentUserData.shelter.operatingHours.includes('-')) {
                        const parts = currentUserData.shelter.operatingHours.split('-');
                        if (parts.length >= 2) {
                            hoursFrom = parts[0].trim();
                            hoursTo = parts[1].trim();
                        }
                    }

                    formHTML += '<div class="md:col-span-2 mt-4 pt-4 border-t border-[#E5E5E5]">' +
                            '<h3 class="text-sm font-medium text-[#2B2B2B] mb-3">Shelter Details</h3>' +
                            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4">' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Shelter Name *</label>' +
                            '<input type="text" name="shelter_name" value="' + (currentUserData.shelter.shelterName || '') + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '</div>' +
                            '<div class="md:col-span-2">' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Shelter Address *</label>' +
                            '<input type="text" name="shelter_address" value="' + (currentUserData.shelter.shelterAddress || '') + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '</div>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Website</label>' +
                            '<input type="url" name="website" value="' + (currentUserData.shelter.website || '') + '" ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]" placeholder="https://example.com">' +
                            '</div>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Operating Hours *</label>' +
                            '<div class="flex gap-2">' +
                            '<div class="flex-1">' +
                            '<input type="time" name="hours_from" value="' + hoursFrom + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '<p class="text-xs text-gray-500 mt-1">Opening time</p>' +
                            '</div>' +
                            '<div class="flex-1">' +
                            '<input type="time" name="hours_to" value="' + hoursTo + '" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '<p class="text-xs text-gray-500 mt-1">Closing time</p>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '<div class="md:col-span-2">' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Shelter Description *</label>' +
                            '<textarea name="shelter_description" rows="3" required ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' + (currentUserData.shelter.shelterDescription || '') + '</textarea>' +
                            '</div>' +
                            '</div>' +
                            '</div>';

                } else if (role === 'admin' && currentUserData.admin) {
                    formHTML += '<div class="md:col-span-2 mt-4 pt-4 border-t border-[#E5E5E5]">' +
                            '<h3 class="text-sm font-medium text-[#2B2B2B] mb-3">Admin Details</h3>' +
                            '<div>' +
                            '<label class="block text-sm font-medium text-[#2B2B2B] mb-1">Position</label>' +
                            '<input type="text" name="position" value="' + (currentUserData.admin.position || '') + '" ' +
                            'class="w-full px-3 py-2 border border-[#E5E5E5] rounded focus:outline-none focus:ring-2 focus:ring-[#2F5D50]">' +
                            '</div>' +
                            '</div>';
                }

                formHTML += '</div>' +
                        '<div class="flex justify-end gap-3 mt-6 pt-4 border-t border-[#E5E5E5]">' +
                        '<button type="button" onclick="closeEditModal()" class="px-6 py-2 bg-[#E5E5E5] text-[#2B2B2B] rounded hover:bg-[#D5D5D5] transition-colors font-medium">Cancel</button>' +
                        '<button type="submit" class="px-6 py-2 bg-[#2F5D50] text-white rounded hover:bg-[#24483E] transition-colors font-medium">Save Changes</button>' +
                        '</div>';

                formContent.innerHTML = formHTML;

                // Show/hide placeholder based on whether we have a preview (SEPERTI LAMA)
                const preview = document.getElementById('edit-profile-preview');
                const placeholder = document.getElementById('edit-upload-placeholder');
                if (preview && placeholder) {
                    if (preview.src.includes('default-avatar.png') || !preview.src) {
                        placeholder.classList.remove('hidden');
                        preview.classList.add('hidden');
                    } else {
                        placeholder.classList.add('hidden');
                        preview.classList.remove('hidden');
                    }
                }
            }

            // Preview image function (SEPERTI LAMA)
            function previewEditImage(event) {
                const file = event.target.files[0];
                const errorElement = document.getElementById('edit-image-error');
                const preview = document.getElementById('edit-profile-preview');
                const placeholder = document.getElementById('edit-upload-placeholder');

                errorElement.classList.add('hidden');
                errorElement.textContent = '';

                if (!file) {
                    selectedFile = null;
                    return;
                }

                const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];
                if (!validTypes.includes(file.type)) {
                    errorElement.textContent = 'Only JPG, PNG, and GIF images are allowed.';
                    errorElement.classList.remove('hidden');
                    event.target.value = '';
                    return;
                }

                const maxSize = 2 * 1024 * 1024;
                if (file.size > maxSize) {
                    errorElement.textContent = 'Image size must be less than 2MB.';
                    errorElement.classList.remove('hidden');
                    event.target.value = '';
                    return;
                }

                const reader = new FileReader();
                reader.onload = function (e) {
                    preview.src = e.target.result;
                    preview.classList.remove('hidden');
                    placeholder.classList.add('hidden');
                    selectedFile = file;
                };
                reader.readAsDataURL(file);
            }

            // Toggle password fields (SEPERTI LAMA)
            function togglePasswordFields() {
                const checkBox = document.getElementById('change-password-check');
                const passwordFields = document.getElementById('password-fields');
                if (checkBox && passwordFields) {
                    passwordFields.classList.toggle('hidden', !checkBox.checked);
                }
            }

            // Show alert function (SEPERTI LAMA)
            function showAlert(message, type = 'success') {
                const alert = document.getElementById('success-alert');
                const alertMessage = document.getElementById('alert-message');
                alertMessage.textContent = message;

                if (type === 'danger') {
                    alert.className = 'fixed top-20 right-6 bg-[#B84A4A] text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50';
                } else {
                    alert.className = 'fixed top-20 right-6 bg-[#6DBF89] text-[#06321F] px-6 py-3 rounded-lg shadow-lg flex items-center gap-3 z-50';
                }

                alert.classList.remove('hidden');
                setTimeout(() => alert.classList.add('hidden'), 3000);
            }

            // Auto-close success message setelah 5 saat (SEPERTI LAMA)
            setTimeout(() => {
                const successAlert = document.getElementById('success-alert');
                if (successAlert && !successAlert.classList.contains('hidden')) {
                    successAlert.classList.add('hidden');
                }
            }, 5000);
        </script>

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>
    </body>
</html>