<%@page import="java.util.ArrayList"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.sql.Timestamp" %>

<%
    // Check if user is logged in and is shelter
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isShelter(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Get data from request attributes yang di-set oleh servlet
    List<Map<String, Object>> allRequests = (List<Map<String, Object>>) request.getAttribute("requests");
    String filter = (String) request.getAttribute("filter");
    String search = (String) request.getAttribute("search");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    Integer shelterId = (Integer) request.getAttribute("shelterId");

    // Default values if attributes are null (first load)
    if (allRequests == null) {
        allRequests = new ArrayList<Map<String, Object>>();
    }

    if (filter == null) {
        filter = "all";
    }
    if (search == null) {
        search = "";
    }
    if (pendingCount == null) {
        pendingCount = 0;
    }
    if (shelterId == null) {
        shelterId = SessionUtil.getUserId(session);
    }

    // Message dari session (untuk success/error messages)
    String message = (String) session.getAttribute("message");
    String messageType = (String) session.getAttribute("messageType");

    // Clear session messages setelah display
    if (message != null) {
        session.removeAttribute("message");
        session.removeAttribute("messageType");
    }

    // Format dates
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("hh:mm a");
%>

<%
// After session check, BEFORE getting attributes
    if (request.getAttribute("requests") == null) {
        // First load - forward to servlet
        request.getRequestDispatcher("ManageAdoptionRequest").forward(request, response);
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Manage Adoption Requests - Rimba Adopt</title>

        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <script>
            tailwind.config = {
                theme: {
                    extend: {
                        colors: {
                            primary: '#2F5D50',
                            'primary-dark': '#24483E',
                            secondary: '#6DBF89',
                            'secondary-dark': '#57A677',
                            'bg-page': '#F6F3E7',
                            'text-main': '#2B2B2B',
                            'chip-pending': '#C49A6C',
                            'chip-approved': '#A8E6CF',
                            'chip-rejected': '#B84A4A',
                            divider: '#E5E5E5'
                        },
                        fontFamily: {
                            sans: ['Inter', 'system-ui', 'sans-serif'],
                        }
                    }
                }
            }
        </script>

        <style>
            /* Modal Styling - Fixed */
            .modal { 
                transition: opacity 0.2s ease, visibility 0.2s ease; 
                opacity: 0; 
                visibility: hidden; 
                display: flex !important;
                align-items: center;
                justify-content: center;
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                z-index: 50;
                padding: 1rem;
            }
            .modal.active { 
                opacity: 1; 
                visibility: visible; 
            }
            .modal-content { 
                transform: scale(0.95); 
                transition: transform 0.2s ease; 
                max-height: 90vh;
                margin: auto;
            }
            .modal.active .modal-content { 
                transform: scale(1); 
            }
            .no-scrollbar::-webkit-scrollbar { 
                display: none; 
            }
            .no-scrollbar { 
                -ms-overflow-style: none; 
                scrollbar-width: none; 
            }
        </style>

        <%-- Toast message display --%>
        <% if (message != null) {%>
        <script>
            document.addEventListener('DOMContentLoaded', function () {
                showToast('<%= "success".equals(messageType) ? "Success" : "Error"%>',
                        '<%= message.replace("'", "\\'")%>',
                        '<%= messageType%>');
            });
        </script>
        <% } %>
    </head>
    <body class="flex flex-col min-h-screen bg-bg-page text-text-main font-sans antialiased">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <main class="flex-1 p-4 md:p-6 flex justify-center items-start">
            <div class="w-full bg-white py-8 px-6 rounded-3xl shadow-lg border border-divider max-w-[1450px]">

                <div class="mb-8">
                    <h1 class="text-3xl md:text-4xl font-extrabold text-primary">Manage Adoption Requests</h1>
                    <p class="mt-2 text-lg text-gray-600">Review and process adoption applications for your shelter pets</p>

                    <div class="mt-6 p-5 rounded-2xl border border-divider bg-bg-page flex flex-col md:flex-row justify-between items-center gap-4">
                        <div class="flex items-center gap-4">
                            <div class="w-16 h-16 rounded-full overflow-hidden border-2 border-primary bg-white">
                                <!-- Shelter profile photo -->
                                <%
                                    String profilePhoto = SessionUtil.getUserProfilePhoto(session);
                                    String profilePhotoSrc = (profilePhoto != null && !profilePhoto.isEmpty())
                                            ? profilePhoto : "https://ui-avatars.com/api/?name=Shelter&background=2F5D50&color=fff";
                                %>
                                <img src="<%= profilePhotoSrc%>" 
                                     class="w-full h-full object-cover" 
                                     onerror="this.src='https://ui-avatars.com/api/?name=Shelter&background=2F5D50&color=fff'">
                            </div>
                            <div>
                                <h3 class="text-xl font-bold text-primary"><%= SessionUtil.getUserName(session)%></h3>
                                <div class="text-sm text-gray-600"><i class="fas fa-map-marker-alt mr-1"></i> Shelter ID: <%= shelterId%></div>
                            </div>
                        </div>
                        <div class="text-right">
                            <div class="text-2xl font-bold text-primary" id="pending-count"><%= pendingCount%></div>
                            <div class="text-xs text-gray-500 uppercase font-bold">Pending Requests</div>
                        </div>
                    </div>
                </div>

                <hr class="border-t border-divider my-6" />

                <!-- Search and Filter Form -->
                <form method="GET" action="ManageAdoptionRequest" class="flex flex-col md:flex-row justify-between items-center gap-4 mb-6">
                    <div class="flex flex-wrap gap-2 w-full md:w-auto" id="filter-container">
                        <button type="submit" name="filter" value="all" 
                                class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all shadow-sm <%= "all".equals(filter) ? "bg-primary text-white border-primary active transform scale-105" : "border-primary text-primary hover:bg-white"%>">
                            All
                        </button>
                        <button type="submit" name="filter" value="pending" 
                                class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all <%= "pending".equals(filter) ? "bg-chip-pending text-white border-chip-pending active transform scale-105" : "border-chip-pending text-chip-pending hover:bg-bg-page"%>">
                            Pending
                        </button>
                        <button type="submit" name="filter" value="approved" 
                                class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all <%= "approved".equals(filter) ? "bg-secondary text-primary-dark border-secondary active transform scale-105" : "border-secondary text-secondary-dark hover:bg-bg-page"%>">
                            Approved
                        </button>
                        <button type="submit" name="filter" value="rejected" 
                                class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all <%= "rejected".equals(filter) ? "bg-chip-rejected text-white border-chip-rejected active transform scale-105" : "border-chip-rejected text-chip-rejected hover:bg-bg-page"%>">
                            Rejected
                        </button>
                        <button type="submit" name="filter" value="cancelled" 
                                class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all <%= "cancelled".equals(filter) ? "bg-gray-500 text-white border-gray-500 active transform scale-105" : "border-gray-400 text-gray-500 hover:bg-bg-page"%>">
                            Cancelled
                        </button>
                    </div>

                    <div class="relative w-full md:w-80">
                        <input type="text" name="search" value="<%= search%>" 
                               placeholder="Search pet or adopter..." 
                               class="w-full py-2.5 pl-10 pr-4 border border-divider rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all bg-bg-page focus:bg-white">
                        <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    </div>

                    <!-- Hidden fields to preserve other parameters -->
                    <input type="hidden" name="action" value="">
                </form>

                <div class="overflow-x-auto rounded-xl border border-divider shadow-sm">
                    <table class="min-w-full divide-y divide-divider">
                        <thead class="bg-bg-page">
                            <tr>
                                <th class="px-6 py-4 text-left text-xs font-bold text-primary uppercase w-16">No.</th>
                                <th class="px-6 py-4 text-left text-xs font-bold text-primary uppercase">Pet Info</th>
                                <th class="px-6 py-4 text-left text-xs font-bold text-primary uppercase">Adopter Info</th>
                                <th class="px-6 py-4 text-left text-xs font-bold text-primary uppercase">Date</th>
                                <th class="px-6 py-4 text-left text-xs font-bold text-primary uppercase">Status</th>
                                <th class="px-6 py-4 text-center text-xs font-bold text-primary uppercase w-32">Action</th>
                            </tr>
                        </thead>
                        <tbody id="requests-table" class="bg-white divide-y divide-divider">
                            <%
                                if (allRequests.isEmpty()) {
                            %>
                            <tr>
                                <td colspan="6" class="px-6 py-12 text-center text-gray-500">
                                    No adoption requests found.
                                    <% if (!"all".equals(filter) || !search.isEmpty()) { %>
                                    <br><a href="ManageAdoptionRequest" class="text-primary hover:underline mt-2 inline-block">Clear filters</a>
                                    <% } %>
                                </td>
                            </tr>
                            <%
                            } else {
                                int counter = 1;
                                for (Map<String, Object> reqItem : allRequests) {
                                    String status = (String) reqItem.get("status");
                                    String statusClass = "";

                                    // REPLACE SWITCH WITH IF-ELSE (Java 1.5 compatible)
                                    if ("pending".equals(status)) {
                                        statusClass = "bg-chip-pending text-white";
                                    } else if ("approved".equals(status)) {
                                        statusClass = "bg-chip-approved text-primary-dark";
                                    } else if ("rejected".equals(status)) {
                                        statusClass = "bg-chip-rejected text-white";
                                    } else {
                                        statusClass = "bg-gray-200 text-gray-600";
                                    }

                                    // Get pet photo or default
                                    String petPhoto = (String) reqItem.get("pet_photo");
                                    if (petPhoto == null || petPhoto.isEmpty()) {
                                        petPhoto = "https://via.placeholder.com/150?text=" + reqItem.get("pet_name");
                                    }

                                    // Get adopter photo or default
                                    String adopterPhoto = (String) reqItem.get("adopter_photo");
                                    if (adopterPhoto == null || adopterPhoto.isEmpty()) {
                                        adopterPhoto = "https://ui-avatars.com/api/?name="
                                                + reqItem.get("adopter_name").toString().replace(" ", "+")
                                                + "&background=2F5D50&color=fff";
                                    }

                                    // Format date
                                    String displayDate = "N/A";
                                    Timestamp requestDate = (Timestamp) reqItem.get("request_date");
                                    if (requestDate != null) {
                                        displayDate = displayDateFormat.format(requestDate);
                                    }

                                    // Helper variables untuk data attributes
                                    Object breedObj = reqItem.get("breed");
                                    String breedStr = (breedObj != null) ? breedObj.toString() : "Mixed";

                                    Object ageObj = reqItem.get("age");
                                    String ageStr = (ageObj != null) ? ageObj.toString() : "N/A";

                                    Object healthObj = reqItem.get("health_status");
                                    String healthStr = (healthObj != null) ? healthObj.toString() : "";

                                    Object notesObj = reqItem.get("notes");
                                    String notesStr = (notesObj != null) ? notesObj.toString() : "No specific notes.";

                                    Object messageObj = reqItem.get("adopter_message");
                                    String messageStr = (messageObj != null) ? messageObj.toString() : "No message provided.";

                                    Object responseObj = reqItem.get("shelter_response");
                                    String responseStr = (responseObj != null) ? responseObj.toString() : "";

                                    Object cancelObj = reqItem.get("cancellation_reason");
                                    String cancelStr = (cancelObj != null) ? cancelObj.toString() : "";

                                    Object hasPetsObj = reqItem.get("has_other_pets");
                                    String hasPetsStr = "No other pets";
                                    if (hasPetsObj != null) {
                                        if (hasPetsObj instanceof Integer) {
                                            hasPetsStr = ((Integer) hasPetsObj == 1) ? "Yes, has pets" : "No other pets";
                                        } else if (hasPetsObj.toString().equals("1")) {
                                            hasPetsStr = "Yes, has pets";
                                        }
                                    }

                                    // Simpan SEMUA data sebagai data attributes untuk modal
                                    String dataAttributes
                                            = "data-request-id='" + reqItem.get("request_id") + "' "
                                            + "data-pet-name='" + escapeHtml((String) reqItem.get("pet_name")) + "' "
                                            + "data-pet-breed='" + escapeHtml(breedStr) + "' "
                                            + "data-pet-species='" + escapeHtml((String) reqItem.get("species")) + "' "
                                            + "data-pet-age='" + escapeHtml(ageStr) + "' "
                                            + "data-pet-gender='" + escapeHtml((String) reqItem.get("gender")) + "' "
                                            + "data-pet-health='" + escapeHtml(healthStr) + "' "
                                            + "data-pet-photo='" + escapeHtml(petPhoto) + "' "
                                            + "data-adopter-name='" + escapeHtml((String) reqItem.get("adopter_name")) + "' "
                                            + "data-adopter-email='" + escapeHtml((String) reqItem.get("adopter_email")) + "' "
                                            + "data-adopter-photo='" + escapeHtml(adopterPhoto) + "' "
                                            + "data-adopter-occupation='" + escapeHtml((String) reqItem.get("occupation")) + "' "
                                            + "data-adopter-household='" + escapeHtml((String) reqItem.get("household_type")) + "' "
                                            + "data-adopter-pets='" + hasPetsStr + "' "
                                            + "data-adopter-notes='" + escapeHtml(notesStr) + "' "
                                            + "data-adopter-message='" + escapeHtml(messageStr) + "' "
                                            + "data-request-date='" + (requestDate != null ? displayDateFormat.format(requestDate) : "N/A") + "' "
                                            + "data-request-time='" + (requestDate != null ? timeFormat.format(requestDate) : "N/A") + "' "
                                            + "data-status='" + status + "' "
                                            + "data-shelter-response='" + escapeHtml(responseStr) + "' "
                                            + "data-cancellation-reason='" + escapeHtml(cancelStr) + "'";
                            %>
                            <tr class="hover:bg-gray-50 transition" <%= dataAttributes%>>
                                <td class="px-6 py-4 text-sm font-medium text-gray-400">
                                    #<%= reqItem.get("request_id")%>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <img class="h-10 w-10 rounded-lg object-cover bg-gray-100" 
                                             src="<%= petPhoto%>"
                                             alt="<%= reqItem.get("pet_name")%>"
                                             onerror="this.src='https://via.placeholder.com/150?text=<%= reqItem.get("pet_name")%>'">
                                        <div>
                                            <div class="text-sm font-bold text-text-main">
                                                <%= reqItem.get("pet_name")%>
                                            </div>
                                            <div class="text-xs text-gray-500">
                                                <%= breedStr%>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <img class="h-8 w-8 rounded-full object-cover border border-divider" 
                                             src="<%= adopterPhoto%>"
                                             alt="<%= reqItem.get("adopter_name")%>"
                                             onerror="this.src='https://ui-avatars.com/api/?name=<%= reqItem.get("adopter_name").toString().replace(" ", "+")%>&background=2F5D50&color=fff'">
                                        <div class="text-sm font-medium">
                                            <%= reqItem.get("adopter_name")%>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 text-sm text-gray-500">
                                    <%= displayDate%>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="px-3 py-1 rounded-full text-xs font-bold <%= statusClass%> capitalize">
                                        <%= status%>
                                    </span>
                                </td>
                                <td class="px-6 py-4 text-center">
                                    <% if ("pending".equals(status)) { %>
                                    <button onclick="openReviewModal(this)" 
                                            class="px-4 py-2 rounded-lg bg-primary text-white text-xs font-bold uppercase tracking-wide hover:bg-primary-dark transition shadow-md hover:shadow-lg transform hover:-translate-y-0.5">
                                        Review
                                    </button>
                                    <% } else { %>
                                    <button onclick="openReviewModal(this)" 
                                            class="px-4 py-2 rounded-lg bg-white border border-gray-300 text-gray-600 text-xs font-bold uppercase tracking-wide hover:bg-gray-50 transition shadow-sm">
                                        View
                                    </button>
                                    <% } %>
                                </td>
                            </tr>
                            <%
                                        counter++;
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>

                <%-- Pagination --%>
                <div class="flex justify-between items-center mt-6">
                    <div class="text-sm text-gray-600">
                        Showing <span class="font-bold text-primary"><%= Math.min(allRequests.size(), 1)%></span> 
                        to <span class="font-bold text-primary"><%= allRequests.size()%></span> 
                        of <span class="font-bold text-primary"><%= allRequests.size()%></span> requests
                    </div>
                    <% if (allRequests.size() > 10) { %>
                    <div class="flex gap-2">
                        <button class="px-4 py-2 text-sm rounded-lg border border-divider hover:bg-gray-100 disabled:opacity-50 transition">Previous</button>
                        <button class="px-4 py-2 text-sm rounded-lg border border-divider hover:bg-gray-100 disabled:opacity-50 transition">Next</button>
                    </div>
                    <% }%>
                </div>
            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Review Modal -->
        <div id="reviewModal" class="modal fixed inset-0 bg-black/60 z-40 p-4 backdrop-blur-sm">
            <form id="reviewForm" method="POST" action="ManageAdoptionRequest" class="w-full">
                <input type="hidden" name="requestId" id="form-request-id">
                <input type="hidden" name="action" id="form-action">

                <div class="modal-content bg-white rounded-2xl w-full max-w-5xl max-h-[95vh] overflow-y-auto shadow-2xl flex flex-col">

                    <div class="flex justify-between items-center p-6 border-b border-divider sticky top-0 bg-white z-10">
                        <div>
                            <h3 class="text-2xl font-bold text-primary">Application Details</h3>
                            <p class="text-xs text-gray-500 font-bold uppercase tracking-wider mt-1">Request ID: #<span id="review-request-id"></span></p>
                        </div>
                        <button type="button" onclick="closeModal('reviewModal')" class="w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition text-gray-500">
                            <i class="fas fa-times text-xl"></i>
                        </button>
                    </div>

                    <div class="p-6 grid grid-cols-1 lg:grid-cols-3 gap-8">

                        <div class="lg:col-span-1 space-y-6">
                            <div class="bg-bg-page rounded-2xl p-6 border border-divider text-center relative overflow-hidden">
                                <div class="absolute top-0 left-0 w-full h-2 bg-primary"></div>
                                <img id="review-pet-photo" src="" class="w-28 h-28 rounded-full mx-auto object-cover border-4 border-white shadow-md mb-4" onerror="this.src='https://via.placeholder.com/150'">
                                <h4 class="text-xl font-bold text-primary" id="review-pet-name"></h4>
                                <p class="text-sm text-gray-600 mb-4" id="review-pet-breed"></p>

                                <div class="flex flex-wrap justify-center gap-2 mb-4">
                                    <span class="px-2.5 py-1 bg-white border border-gray-200 rounded-md text-xs font-bold text-gray-600" id="review-pet-gender"></span>
                                    <span class="px-2.5 py-1 bg-white border border-gray-200 rounded-md text-xs font-bold text-gray-600" id="review-pet-age"></span>
                                </div>
                                <span class="inline-block px-3 py-1 bg-green-100 text-green-800 text-xs font-bold rounded-full" id="review-pet-health"></span>
                            </div>

                            <div class="bg-white rounded-2xl p-5 border border-divider shadow-sm">
                                <h5 class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">Timeline</h5>
                                <div class="relative pl-4 border-l-2 border-gray-100 space-y-6">
                                    <div class="relative">
                                        <div class="absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-primary border-2 border-white shadow-sm"></div>
                                        <p class="text-xs font-bold text-primary uppercase">Request Submitted</p>
                                        <p class="text-sm text-gray-700 font-medium mt-0.5" id="review-request-date"></p>
                                        <p class="text-xs text-gray-400" id="review-request-time"></p>
                                    </div>
                                    <div class="relative">
                                        <div id="review-status-dot" class="absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-gray-300 border-2 border-white shadow-sm"></div>
                                        <p class="text-xs font-bold text-gray-500 uppercase">Current Status</p>
                                        <span id="review-status-badge" class="inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white bg-gray-400"></span>
                                    </div>
                                </div>

                                <div id="cancellation-block" class="hidden mt-6 bg-red-50 p-4 rounded-xl border border-red-100">
                                    <div class="flex items-start gap-3">
                                        <i class="fas fa-ban text-red-500 mt-0.5"></i>
                                        <div>
                                            <p class="text-xs font-bold text-red-800 uppercase">Cancellation Reason</p>
                                            <p class="text-sm text-red-700 italic mt-1" id="review-cancellation-reason"></p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="lg:col-span-2 flex flex-col h-full">

                            <div class="flex items-start gap-5 mb-6">
                                <img id="review-adopter-photo" src="" class="w-16 h-16 rounded-xl object-cover border border-divider shadow-sm" onerror="this.src='https://ui-avatars.com/api/?name=User&background=2F5D50&color=fff'">
                                <div>
                                    <h4 class="text-2xl font-bold text-text-main" id="review-adopter-name"></h4>
                                    <div class="flex flex-wrap gap-x-6 gap-y-1 text-sm text-gray-600 mt-1">
                                        <span class="flex items-center"><i class="fas fa-briefcase w-5 text-primary opacity-70"></i> <span id="review-adopter-occupation"></span></span>
                                        <span class="flex items-center"><i class="fas fa-envelope w-5 text-primary opacity-70"></i> <span id="review-adopter-email"></span></span>
                                    </div>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                                <div class="p-4 rounded-xl border border-divider bg-bg-page">
                                    <p class="text-xs font-bold text-gray-500 uppercase mb-2">Living Environment</p>
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-full bg-white flex items-center justify-center text-primary shadow-sm"><i class="fas fa-home text-sm"></i></div>
                                        <span class="font-bold text-text-main capitalize" id="review-adopter-house"></span>
                                    </div>
                                </div>
                                <div class="p-4 rounded-xl border border-divider bg-bg-page">
                                    <p class="text-xs font-bold text-gray-500 uppercase mb-2">Existing Pets</p>
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-full bg-white flex items-center justify-center text-primary shadow-sm"><i class="fas fa-paw text-sm"></i></div>
                                        <span class="font-bold" id="review-adopter-pets"></span>
                                    </div>
                                </div>
                                <div class="md:col-span-2 p-4 rounded-xl border border-divider bg-white">
                                    <p class="text-xs font-bold text-gray-500 uppercase mb-1">Safety & Notes</p>
                                    <p class="text-sm text-gray-700 leading-relaxed" id="review-adopter-notes"></p>
                                </div>
                            </div>

                            <div class="mb-6">
                                <label class="text-xs font-bold text-gray-500 uppercase mb-2 block">Reason for Adoption</label>
                                <div class="p-5 bg-gray-50 rounded-xl border border-divider text-gray-700 italic text-sm leading-relaxed">
                                    <span id="review-adopter-message"></span>
                                </div>
                            </div>

                            <div class="mt-auto pt-6 border-t border-divider">

                                <div id="action-section">
                                    <label class="block text-sm font-bold text-primary mb-2">Shelter Response (Required)</label>
                                    <textarea name="shelterResponse" id="shelter-response" rows="3" 
                                              class="w-full p-4 border border-divider rounded-xl focus:ring-2 focus:ring-primary focus:outline-none mb-4 text-sm bg-white shadow-sm resize-none" 
                                              placeholder="Write a response to the adopter..." required></textarea>

                                    <div class="flex flex-col sm:flex-row justify-end gap-3">
                                        <button type="button" onclick="closeModal('reviewModal')" 
                                                class="px-5 py-2.5 rounded-xl border border-divider bg-white hover:bg-gray-50 text-gray-600 font-medium transition">
                                            Cancel
                                        </button>

                                        <button type="button" onclick="promptConfirmation('reject')" 
                                                class="px-6 py-2.5 rounded-xl bg-chip-rejected hover:bg-red-700 text-white font-bold shadow-md transition flex items-center justify-center">
                                            <i class="fas fa-times mr-2"></i>Reject
                                        </button>
                                        <button type="button" onclick="promptConfirmation('approve')" 
                                                class="px-6 py-2.5 rounded-xl bg-primary hover:bg-primary-dark text-white font-bold shadow-md transition flex items-center justify-center">
                                            <i class="fas fa-check mr-2"></i>Approve Request
                                        </button>
                                    </div>
                                </div>

                                <div id="readonly-footer" class="hidden">
                                    <div class="mb-4">
                                        <span class="font-bold text-sm block mb-2 text-primary">Shelter Response Sent:</span>
                                        <div class="p-4 bg-white border border-divider rounded-xl text-sm text-gray-700" id="readonly-response-text"></div>
                                    </div>
                                    <div class="flex justify-end">
                                        <button type="button" onclick="closeModal('reviewModal')" 
                                                class="px-6 py-2.5 rounded-xl bg-gray-200 text-gray-800 hover:bg-gray-300 font-bold transition">
                                            Close Details
                                        </button>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>

        <!-- Confirmation Modal -->
        <div id="confirmationModal" class="modal fixed inset-0 bg-black/70 z-[60]">
            <div class="modal-content bg-white rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center">

                <div id="confirm-icon-container" class="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 transition-colors">
                    <i id="confirm-icon" class="fas fa-question text-3xl text-white"></i>
                </div>

                <h3 class="text-xl font-bold text-text-main mb-2" id="confirm-title">Are you sure?</h3>
                <p class="text-gray-500 text-sm mb-6" id="confirm-desc">This action cannot be undone.</p>

                <div class="flex gap-3 justify-center">
                    <button type="button" onclick="closeModal('confirmationModal')" class="flex-1 py-2.5 rounded-xl border border-divider text-gray-600 font-medium hover:bg-gray-50 transition">No, Cancel</button>
                    <button type="button" id="confirm-yes-btn" class="flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90">Yes, Confirm</button>
                </div>
            </div>
        </div>

        <!-- Toast Notification -->
        <div id="toast" class="fixed top-5 right-5 z-[70] transform transition-all duration-300 translate-x-full opacity-0">
            <div class="flex items-center p-4 rounded-xl shadow-xl min-w-[300px]" id="toast-bg">
                <div class="mr-3 text-2xl" id="toast-icon"></div>
                <div>
                    <h4 class="font-bold text-white" id="toast-title"></h4>
                    <p class="text-white/90 text-sm" id="toast-message"></p>
                </div>
            </div>
        </div>

        <script>
            // =======================================================
            // 1. CONFIGURATION AND STATE MANAGEMENT
            // =======================================================
            const DEBUG = false;
            let state = {
                currentId: null,
                pendingAction: null,
                imagesLoaded: false,
                pageLoaded: false
            };

            // =======================================================
            // 2. IMAGE LOADING HANDLER (PENTING!)
            // =======================================================
            function handleAllImagesLoaded() {
                return new Promise((resolve) => {
                    const images = document.querySelectorAll('img');
                    const totalImages = images.length;
                    let loadedCount = 0;

                    if (DEBUG)
                        console.log(`Checking ${totalImages} images...`);

                    if (totalImages === 0) {
                        state.imagesLoaded = true;
                        resolve();
                        return;
                    }

                    // Function to track image loading
                    function trackImageLoad(img) {
                        if (img.complete && img.naturalHeight !== 0) {
                            loadedCount++;
                        } else {
                            img.addEventListener('load', () => {
                                loadedCount++;
                                checkCompletion();
                            });
                            img.addEventListener('error', () => {
                                loadedCount++; // Count errors as loaded
                                checkCompletion();
                            });
                        }
                    }

                    function checkCompletion() {
                        if (loadedCount >= totalImages) {
                            state.imagesLoaded = true;
                            if (DEBUG)
                                console.log(`All images loaded: ${loadedCount}/${totalImages}`);
                            resolve();
                        }
                    }

                    // Track each image
                    images.forEach(trackImageLoad);
                    checkCompletion(); // Check if already all loaded

                    // Fallback timeout (4 seconds)
                    setTimeout(() => {
                        if (!state.imagesLoaded) {
                            state.imagesLoaded = true;
                            if (DEBUG)
                                console.warn(`Image loading timeout. Loaded: ${loadedCount}/${totalImages}`);
                            resolve();
                        }
                    }, 4000);
                });
            }

            // =======================================================
            // 3. FORCE STOP LOADING INDICATOR (UTAMA!)
            // =======================================================
            function forceStopLoadingIndicator() {
                try {
                    if (state.pageLoaded)
                        return;

                    state.pageLoaded = true;

                    if (DEBUG)
                        console.log('Force stopping browser loading indicator...');

                    // Method 1: window.stop() - stops all pending requests
                    if (window.stop && typeof window.stop === 'function') {
                        window.stop();
                    }

                    // Method 2: Mark page as fully loaded
                    document.documentElement.setAttribute('data-page-loaded', 'true');
                    document.body.classList.add('page-loaded-complete');

                    // Method 3: Hide any loading animations
                    const loadingAnimations = document.querySelectorAll('[class*="fa-spinner"], [class*="loading"]');
                    loadingAnimations.forEach(el => {
                        el.style.display = 'none';
                    });

                    if (DEBUG)
                        console.log('Loading indicator stopped successfully');
                } catch (e) {
                    if (DEBUG)
                        console.warn('Error stopping loading indicator:', e);
                }
            }

            // =======================================================
            // 4. MODAL FUNCTIONS - FIXED VERSION
            // =======================================================
            function openReviewModal(button) {
                // Prevent multiple clicks
                if (button.disabled)
                    return;
                button.disabled = true;

                setTimeout(() => {
                    button.disabled = false;
                }, 1000);

                // Get the parent row
                const row = button.closest('tr');
                if (!row) {
                    if (DEBUG)
                        console.error('No row found for button');
                    return;
                }

                // Extract data from data attributes
                const requestId = row.dataset.requestId;
                const status = row.dataset.status;

                if (DEBUG)
                    console.log(`Opening review modal for request ${requestId}, status: ${status}`);

                // Update modal dengan data dari row
                document.getElementById('review-request-id').textContent = requestId;
                document.getElementById('form-request-id').value = requestId;

                // Update pet info
                document.getElementById('review-pet-name').textContent = row.dataset.petName || 'Unknown';
                document.getElementById('review-pet-breed').textContent = (row.dataset.petBreed || 'Unknown') + ' (' + (row.dataset.petSpecies || 'Unknown') + ')';
                document.getElementById('review-pet-gender').textContent = row.dataset.petGender || 'Unknown';
                document.getElementById('review-pet-age').textContent = row.dataset.petAge || 'Unknown';
                document.getElementById('review-pet-health').textContent = row.dataset.petHealth || 'Unknown';

                // Update pet photo dengan error handling
                const petPhotoEl = document.getElementById('review-pet-photo');
                const petPhoto = row.dataset.petPhoto;
                if (petPhoto && petPhoto !== 'null' && petPhoto.trim() !== '') {
                    petPhotoEl.src = petPhoto;
                    petPhotoEl.onerror = function () {
                        this.src = 'https://via.placeholder.com/150?text=' + encodeURIComponent(row.dataset.petName || 'Pet');
                    };
                } else {
                    petPhotoEl.src = 'https://via.placeholder.com/150?text=' + encodeURIComponent(row.dataset.petName || 'Pet');
                }

                // Update adopter info
                document.getElementById('review-adopter-name').textContent = row.dataset.adopterName || 'Unknown';
                document.getElementById('review-adopter-email').textContent = row.dataset.adopterEmail || 'Unknown';
                document.getElementById('review-adopter-occupation').textContent = row.dataset.adopterOccupation || 'Not specified';
                document.getElementById('review-adopter-house').textContent = (row.dataset.adopterHousehold || 'unknown').replace('_', ' ');
                document.getElementById('review-adopter-notes').textContent = row.dataset.adopterNotes || 'No notes provided';
                document.getElementById('review-adopter-message').textContent = row.dataset.adopterMessage || 'No message provided';

                // Update adopter photo dengan error handling
                const adopterPhotoEl = document.getElementById('review-adopter-photo');
                const adopterPhoto = row.dataset.adopterPhoto;
                if (adopterPhoto && adopterPhoto !== 'null' && adopterPhoto.trim() !== '') {
                    adopterPhotoEl.src = adopterPhoto;
                    adopterPhotoEl.onerror = function () {
                        this.src = 'https://ui-avatars.com/api/?name=' +
                                encodeURIComponent(row.dataset.adopterName || 'User') +
                                '&background=2F5D50&color=fff';
                    };
                } else {
                    adopterPhotoEl.src = 'https://ui-avatars.com/api/?name=' +
                            encodeURIComponent(row.dataset.adopterName || 'User') +
                            '&background=2F5D50&color=fff';
                }

                // Update existing pets
                const petsElement = document.getElementById('review-adopter-pets');
                if (row.dataset.adopterPets === 'Yes, has pets') {
                    petsElement.textContent = "Yes, has pets";
                    petsElement.className = "font-bold text-yellow-600";
                } else {
                    petsElement.textContent = "No other pets";
                    petsElement.className = "font-bold text-green-600";
                }

                // Update timeline
                document.getElementById('review-request-date').textContent = row.dataset.requestDate || 'N/A';
                document.getElementById('review-request-time').textContent = row.dataset.requestTime || 'N/A';

                // Update status badge
                const statusBadgeEl = document.getElementById('review-status-badge');
                const statusDot = document.getElementById('review-status-dot');

                statusBadgeEl.textContent = (status || 'unknown').toUpperCase();

                // Set status colors
                if (status === 'pending') {
                    statusBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white bg-chip-pending';
                    statusDot.className = 'absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-chip-pending border-2 border-white shadow-sm';
                } else if (status === 'approved') {
                    statusBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold bg-chip-approved !text-primary-dark';
                    statusDot.className = 'absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-secondary border-2 border-white shadow-sm';
                } else if (status === 'rejected') {
                    statusBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white bg-chip-rejected';
                    statusDot.className = 'absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-chip-rejected border-2 border-white shadow-sm';
                } else {
                    statusBadgeEl.className = 'inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white bg-gray-400';
                    statusDot.className = 'absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-gray-400 border-2 border-white shadow-sm';
                }

                // Show/hide action section based on status
                const actionSec = document.getElementById('action-section');
                const footerSec = document.getElementById('readonly-footer');
                const responseBox = document.getElementById('shelter-response');
                const readonlyResponse = document.getElementById('readonly-response-text');

                if (status === 'pending') {
                    actionSec.classList.remove('hidden');
                    footerSec.classList.add('hidden');
                    responseBox.value = '';
                    responseBox.required = true;
                } else {
                    actionSec.classList.add('hidden');
                    footerSec.classList.remove('hidden');
                    responseBox.required = false;

                    // Show existing shelter response if any
                    const shelterResponse = row.dataset.shelterResponse;
                    if (shelterResponse && shelterResponse !== 'null' && shelterResponse.trim() !== '') {
                        readonlyResponse.textContent = shelterResponse;
                    } else {
                        readonlyResponse.textContent = 'No response recorded.';
                    }
                }

                // Show/hide cancellation reason
                const cancelBlock = document.getElementById('cancellation-block');
                const cancelReason = row.dataset.cancellationReason;
                if (status === 'cancelled' && cancelReason && cancelReason !== 'null' && cancelReason.trim() !== '') {
                    cancelBlock.classList.remove('hidden');
                    document.getElementById('review-cancellation-reason').textContent = cancelReason;
                } else {
                    cancelBlock.classList.add('hidden');
                }

                // Store current state
                state.currentId = requestId;

                // Open modal
                document.getElementById('reviewModal').classList.add('active');
                document.body.style.overflow = 'hidden';

                if (DEBUG)
                    console.log('Review modal opened successfully');
            }

            function closeModal(modalId) {
                const modal = document.getElementById(modalId);
                if (!modal)
                    return;

                modal.classList.remove('active');
                document.body.style.overflow = '';

                if (modalId === 'reviewModal') {
                    // Reset state
                    state.currentId = null;
                    state.pendingAction = null;
                }

                if (DEBUG)
                    console.log(`Modal ${modalId} closed`);
            }

            function promptConfirmation(type) {
                const responseVal = document.getElementById('shelter-response').value.trim();
                if (!responseVal) {
                    showToast('Action Failed', 'Please write a response message first.', 'error');
                    document.getElementById('shelter-response').focus();
                    return;
                }

                state.pendingAction = type;

                const title = document.getElementById('confirm-title');
                const iconContainer = document.getElementById('confirm-icon-container');
                const icon = document.getElementById('confirm-icon');
                const confirmBtn = document.getElementById('confirm-yes-btn');

                if (type === 'approve') {
                    title.innerText = "Approve Application?";
                    iconContainer.className = "w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 bg-secondary";
                    icon.className = "fas fa-check text-3xl text-primary-dark";
                    confirmBtn.className = "flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90 bg-primary";
                    confirmBtn.textContent = "Yes, Approve";
                } else {
                    title.innerText = "Reject Application?";
                    iconContainer.className = "w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 bg-chip-rejected";
                    icon.className = "fas fa-times text-3xl text-white";
                    confirmBtn.className = "flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90 bg-chip-rejected";
                    confirmBtn.textContent = "Yes, Reject";
                }

                confirmBtn.onclick = executeAction;
                document.getElementById('confirmationModal').classList.add('active');
                document.body.style.overflow = 'hidden';
            }

            function executeAction() {
                const action = state.pendingAction;
                const form = document.getElementById('reviewForm');
                const actionInput = document.getElementById('form-action');
                const requestIdInput = document.getElementById('form-request-id');
                const responseVal = document.getElementById('shelter-response').value.trim();

                if (!responseVal) {
                    showToast('Action Failed', 'Please write a response message first.', 'error');
                    document.getElementById('shelter-response').focus();
                    return;
                }

                if (!state.currentId) {
                    showToast('Error', 'No request selected.', 'error');
                    return;
                }

                // Set form values
                actionInput.value = action;
                requestIdInput.value = state.currentId;

                // Show loading state
                const confirmBtn = document.getElementById('confirm-yes-btn');
                const originalText = confirmBtn.textContent;
                confirmBtn.disabled = true;
                confirmBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Processing...';

                // Submit form after short delay
                setTimeout(() => {
                    if (DEBUG)
                        console.log(`Submitting form: action=${action}, requestId=${state.currentId}`);
                    form.submit();
                }, 300);
            }

            // =======================================================
            // 5. TOAST NOTIFICATION
            // =======================================================
            function showToast(title, msg, type) {
                const toast = document.getElementById('toast');
                const bg = document.getElementById('toast-bg');
                const icon = document.getElementById('toast-icon');

                document.getElementById('toast-title').innerText = title;
                document.getElementById('toast-message').innerText = msg;

                // Reset classes
                bg.className = "flex items-center p-4 rounded-xl shadow-xl min-w-[300px]";

                if (type === 'success') {
                    bg.classList.add('bg-secondary', 'text-primary-dark', 'border', 'border-secondary-dark');
                    icon.innerHTML = '<i class="fas fa-check-circle"></i>';
                } else if (type === 'error') {
                    bg.classList.add('bg-chip-rejected', 'text-white');
                    icon.innerHTML = '<i class="fas fa-exclamation-triangle"></i>';
                } else if (type === 'warning') {
                    bg.classList.add('bg-yellow-500', 'text-white');
                    icon.innerHTML = '<i class="fas fa-exclamation-circle"></i>';
                }

                // Show toast
                toast.classList.remove('translate-x-full', 'opacity-0');
                toast.classList.add('translate-x-0', 'opacity-100');

                // Auto hide after 4 seconds
                setTimeout(() => {
                    toast.classList.remove('translate-x-0', 'opacity-100');
                    toast.classList.add('translate-x-full', 'opacity-0');
                }, 4000);
            }

            // =======================================================
            // 6. INITIALIZATION AND EVENT HANDLERS
            // =======================================================
            document.addEventListener('DOMContentLoaded', function () {
                if (DEBUG)
                    console.log('Manage Requests page - DOM loaded');

                // Filter button active state
                const filterButtons = document.querySelectorAll('.filter-btn');
                filterButtons.forEach(btn => {
                    if (btn.classList.contains('active')) {
                        btn.classList.add('transform', 'scale-105');
                    }
                });

                // Handle image loading
                handleAllImagesLoaded().then(() => {
                    if (DEBUG)
                        console.log('All images loaded successfully');
                }).catch(err => {
                    if (DEBUG)
                        console.warn('Image loading issue:', err);
                });

                // Auto-hide toast messages if any
                setTimeout(() => {
                    const messages = document.querySelectorAll('.fixed.top-4');
                    messages.forEach(msg => {
                        msg.style.display = 'none';
                    });
                }, 5000);

                // Close modal on ESC key
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape') {
                        closeModal('reviewModal');
                        closeModal('confirmationModal');
                    }
                });

                // Close modal when clicking outside
                document.addEventListener('click', (e) => {
                    if (e.target.classList.contains('modal') && e.target.classList.contains('active')) {
                        closeModal(e.target.id);
                    }
                });

                // Disable double form submissions
                const forms = document.querySelectorAll('form');
                forms.forEach(form => {
                    let isSubmitting = false;
                    form.addEventListener('submit', (e) => {
                        if (isSubmitting) {
                            e.preventDefault();
                            return;
                        }
                        isSubmitting = true;

                        // Re-enable after 3 seconds (in case of error)
                        setTimeout(() => {
                            isSubmitting = false;
                        }, 3000);
                    });
                });
            });

            // =======================================================
            // 7. WINDOW LOAD EVENT - UTAMA UNTUK STOP LOADING ICON
            // =======================================================
            window.addEventListener('load', function () {
                if (DEBUG)
                    console.log('Manage Requests page - Window fully loaded');

                // Force stop loading indicator after 500ms
                setTimeout(() => {
                    forceStopLoadingIndicator();
                }, 500);
            });

            // =======================================================
            // 8. FALLBACK TIMEOUT - JIKA WINDOW.LOAD TAK TRIGGER
            // =======================================================
            setTimeout(() => {
                if (!state.pageLoaded) {
                    if (DEBUG)
                        console.warn('Fallback: Forcing page load completion after 7 seconds');
                    forceStopLoadingIndicator();
                }
            }, 7000);

            // =======================================================
            // 9. ERROR HANDLING (PREVENT LOADING HANG)
            // =======================================================
            window.addEventListener('error', function (event) {
                if (DEBUG)
                    console.error('JavaScript error:', event.error);
                // Prevent error from stopping page load
                event.preventDefault();
            });

            window.addEventListener('unhandledrejection', function (event) {
                if (DEBUG)
                    console.error('Unhandled promise rejection:', event.reason);
                event.preventDefault(); // Prevent browser error display
            });

            // =======================================================
            // 10. PREVENT MULTIPLE MODAL OPENINGS
            // =======================================================
            document.addEventListener('click', function (e) {
                // Prevent clicking review button multiple times
                if (e.target.closest && e.target.closest('button[onclick*="openReviewModal"]')) {
                    const button = e.target.closest('button[onclick*="openReviewModal"]');
                    if (button.disabled) {
                        e.preventDefault();
                        e.stopPropagation();
                    }
                }
            });
        </script>

        <%!
            // Helper method to escape JavaScript strings
            private String escapeJavaScript(String input) {
                if (input == null) {
                    return "";
                }
                return input
                        .replace("\\", "\\\\")
                        .replace("\"", "\\\"")
                        .replace("'", "\\'")
                        .replace("\n", "\\n")
                        .replace("\r", "\\r")
                        .replace("\t", "\\t");
            }
        %>

        <script src="includes/sidebar.js"></script>
    </body>
</html>

<%!
    // Helper function to escape HTML
    private String escapeHtml(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("'", "&#39;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\n", "<br>");
    }
%>
