<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.FeedbackDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.Timestamp" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%
    // Debug log
    System.out.println("DEBUG feedback_list.jsp - Starting...");
    System.out.println("DEBUG - isLoggedIn: " + SessionUtil.isLoggedIn(session));
    System.out.println("DEBUG - isAdopter: " + SessionUtil.isAdopter(session));

    // Check if user is logged in and is adopter
    if (!SessionUtil.isLoggedIn(session)) {
        System.out.println("DEBUG - User not logged in, redirecting to index.jsp");
        response.sendRedirect("index.jsp");
        return; // CRITICAL: Stop execution
    }

    if (!SessionUtil.isAdopter(session)) {
        System.out.println("DEBUG - User not adopter, redirecting to index.jsp");
        response.sendRedirect("index.jsp");
        return; // CRITICAL: Stop execution
    }

    // Get adopter ID
    int adopterId = SessionUtil.getUserId(session);
    FeedbackDAO feedbackDAO = new FeedbackDAO();

    // Initialize variables
    List feedbackList = new ArrayList();
    int totalCount = 0;
    int[] ratingCounts = new int[6]; // index 0 not used, 1-5 for ratings

    // Get feedback data for this adopter
    try {
        feedbackList = feedbackDAO.getFeedbackByAdopterId(adopterId);
        totalCount = feedbackList.size();

        System.out.println("DEBUG - Total feedback found: " + totalCount);

        // Calculate rating distribution
        for (int i = 0; i < ratingCounts.length; i++) {
            ratingCounts[i] = 0;
        }

        for (int i = 0; i < feedbackList.size(); i++) {
            Object[] feedback = (Object[]) feedbackList.get(i);
            Integer rating = (Integer) feedback[2];
            if (rating >= 1 && rating <= 5) {
                ratingCounts[rating]++;
            }
        }

        // Store in request scope untuk JSTL
        request.setAttribute("feedbackList", feedbackList);

    } catch (Exception e) {
        e.printStackTrace();
        System.out.println("DEBUG - Error loading feedback: " + e.getMessage());
        request.setAttribute("error", "Failed to load feedback data: " + e.getMessage());
    }

    System.out.println("DEBUG feedback_list.jsp - Finished loading data");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>My Feedback - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
        <style>
            /* Custom utility classes based on your theme */
            .text-main { color: #2B2B2B; }
            .bg-primary { background-color: #2F5D50; }
            .hover-bg-primary-dark { background-color: #24483E; }
            .text-white-on-dark { color: #FFFFFF; }
            .border-divider { border-color: #E5E5E5; }
            /* Rating Star Styles */
            .star-filter { background-color: #FFD700; color: #2B2B2B; }
            .star-display { color: #FFD700; }
            /* Modal Styles */
            .modal {
                transition: opacity 0.25s ease;
            }
            /* Custom focus styles */
            .custom-focus:focus {
                outline: none;
                ring: 2px;
                ring-color: #2F5D50;
                border-color: #2F5D50;
            }
            /* Equal width for action buttons */
            .action-button {
                width: 120px;
                padding: 0.5rem 0;
                text-align: center;
            }
            /* Rating stars interactive */
            .rating-star {
                cursor: pointer;
                transition: all 0.2s;
            }
            .rating-star:hover {
                transform: scale(1.2);
            }
            .rating-star.filled {
                color: #FFD700;
            }
            .rating-star.empty {
                color: #E5E5E5;
            }

            /* Animation for messages */
            @keyframes slideIn {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            .animate-slideIn {
                animation: slideIn 0.3s ease-out;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7] text-main">
        <!-- Success/Error Messages -->
        <c:if test="${not empty sessionScope.success}">
            <div class="fixed top-4 right-4 z-50 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded-lg shadow-lg animate-slideIn">
                <div class="flex items-center">
                    <i class="fas fa-check-circle mr-2"></i>
                    <span>${sessionScope.success}</span>
                </div>
            </div>
            <% session.removeAttribute("success"); %>
        </c:if>

        <c:if test="${not empty sessionScope.error}">
            <div class="fixed top-4 right-4 z-50 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg shadow-lg animate-slideIn">
                <div class="flex items-center">
                    <i class="fas fa-exclamation-circle mr-2"></i>
                    <span>${sessionScope.error}</span>
                </div>
            </div>
            <% session.removeAttribute("error");%>
        </c:if>

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2" style="background-color: #F6F3E7;">
            <div class="w-full bg-white py-8 px-6 rounded-3xl shadow-xl border" style="max-width: 1450px; border-color: #E5E5E5;">
                <div class="mb-8">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">My Feedback</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">View and manage your feedback to shelters here.</p>
                </div>
                <hr style="border-top: 1px solid #E5E5E5; margin-bottom: 1.5rem; margin-top: 1.5rem;" />

                <div class="flex flex-col md:flex-row justify-between items-center mb-6 space-y-4 md:space-y-0">
                    <div class="flex flex-wrap gap-2 text-sm font-medium">
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary active-filter" data-rating="all">All (<%= totalCount%>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFD700] text-[#2B2B2B]" data-rating="5">⭐ 5 Stars (<%= ratingCounts[5]%>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFD700] text-[#2B2B2B]" data-rating="4">⭐ 4 Stars (<%= ratingCounts[4]%>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFD700] text-[#2B2B2B]" data-rating="3">⭐ 3 Stars (<%= ratingCounts[3]%>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFD700] text-[#2B2B2B]" data-rating="2">⭐ 2 Stars (<%= ratingCounts[2]%>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFD700] text-[#2B2B2B]" data-rating="1">⭐ 1 Star (<%= ratingCounts[1]%>)</button>
                    </div>
                    <div class="relative w-full md:w-80">
                        <input type="text" id="searchInput" placeholder="Search Shelter..." class="w-full py-2.5 pl-10 pr-4 border rounded-xl transition duration-150 shadow-sm text-base custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                        <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    </div>
                </div>

                <div class="overflow-x-auto rounded-xl border shadow-lg" style="border-color: #E5E5E5;">
                    <table class="min-w-full divide-y" style="border-color: #E5E5E5;">
                        <thead style="background-color: #F6F3E7;">
                            <tr>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 5%;">No.</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Shelter</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Rating</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Comment</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Date</th>
                                <th class="px-6 py-4 text-center text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 15%;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="feedback-list" class="bg-white divide-y" style="border-color: #E5E5E5;">
                            <c:choose>
                                <c:when test="${not empty feedbackList}">
                                    <c:forEach var="feedbackItem" items="${feedbackList}" varStatus="loop">
                                        <%
                                            // Get data from list
                                            Object[] feedback = (Object[]) pageContext.getAttribute("feedbackItem");
                                            Integer feedbackId = (Integer) feedback[0];
                                            String shelterName = (String) feedback[1];
                                            Integer rating = (Integer) feedback[2];
                                            String comment = (String) feedback[3];
                                            Timestamp createdAt = (Timestamp) feedback[4];
                                            String shelterLogo = (String) feedback[5];

                                            // Format date
                                            String formattedDate = createdAt.toString().split(" ")[0];
                                            String truncatedComment = comment.length() > 80 ? comment.substring(0, 80) + "..." : comment;

                                            // Store in page scope for JSTL
                                            pageContext.setAttribute("feedbackId", feedbackId);
                                            pageContext.setAttribute("shelterName", shelterName);
                                            pageContext.setAttribute("rating", rating);
                                            pageContext.setAttribute("truncatedComment", truncatedComment);
                                            pageContext.setAttribute("fullComment", comment);
                                            pageContext.setAttribute("formattedDate", formattedDate);
                                            pageContext.setAttribute("shelterLogo", shelterLogo);
                                        %>
                                        <tr class="hover:bg-gray-50 transition duration-100 feedback-row" 
                                            data-rating="${rating}"
                                            data-feedbackid="${feedbackId}"
                                            data-sheltername="${shelterName}"
                                            data-fullcomment="${fullComment}"
                                            data-date="${formattedDate}">
                                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;">${loop.index + 1}</td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <div class="flex items-center">
                                                    <div class="flex-shrink-0 h-10 w-10">
                                                        <img class="h-10 w-10 rounded-full object-cover" src="${shelterLogo != null ? shelterLogo : 'https://via.placeholder.com/40x40?text=Shelter'}" alt="${shelterName}" onerror="this.src='https://via.placeholder.com/40x40?text=Shelter'">
                                                    </div>
                                                    <div class="ml-4">
                                                        <div class="text-sm font-medium shelter-name" style="color: #2B2B2B;">${shelterName}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <div class="flex items-center space-x-1">
                                                    <c:forEach begin="1" end="5" var="star">
                                                        <c:choose>
                                                            <c:when test="${star <= rating}">
                                                                <i class="fas fa-star star-display"></i>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <i class="far fa-star" style="color: #E5E5E5;"></i>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </c:forEach>
                                                </div>
                                            </td>
                                            <td class="px-6 py-4 text-sm max-w-xs feedback-comment" style="color: #2B2B2B;">
                                                ${truncatedComment}
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm feedback-date" style="color: #2B2B2B;">${formattedDate}</td>
                                            <td class="px-6 py-4 whitespace-nowrap text-center">
                                                <div class="flex flex-col items-center space-y-2">
                                                    <button onclick="openEditModal(${feedbackId})" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View/Edit</button>
                                                    <button onclick="openDeleteModal(${feedbackId})" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-red-700" style="background-color: #B84A4A;">Delete</button>
                                                </div>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <tr>
                                        <td colspan="6" class="px-6 py-8 text-center text-gray-500">
                                            <i class="fas fa-comment-slash text-4xl mb-2"></i>
                                            <p class="text-lg">No feedback found.</p>
                                            <p class="text-sm">You haven't submitted any feedback to shelters yet.</p>
                                        </td>
                                    </tr>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>

                <div id="pagination-controls" class="flex justify-between items-center mt-6">
                    <div class="text-sm" style="color: #2B2B2B;">
                        Showing <span id="start-index" class="font-semibold">1</span> to <span id="end-index" class="font-semibold"><%= Math.min(totalCount, 10)%></span> of <span id="total-items" class="font-semibold"><%= totalCount%></span> feedback
                    </div>
                    <div class="flex space-x-2">
                        <button id="prev-btn" class="px-4 py-2 text-sm rounded-xl border text-[#2B2B2B] hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition duration-150" style="border-color: #E5E5E5;">
                            Previous
                        </button>
                        <button id="next-btn" class="px-4 py-2 text-sm rounded-xl border text-[#2B2B2B] hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition duration-150" style="border-color: #E5E5E5;">
                            Next
                        </button>
                    </div>
                </div>
            </div>
        </main>

        <!-- Edit Modal -->
        <div id="editModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-2xl mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #2F5D50;">Edit Feedback</h3>
                    <button onclick="closeModal('editModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="max-h-[70vh] overflow-y-auto pr-2">
                    <!-- GUNA AJAX untuk form submission -->
                    <form id="editForm" method="POST" class="space-y-4" onsubmit="return submitEditForm(event)">
                        <input type="hidden" name="action" value="updateFeedback">
                        <input type="hidden" id="editFeedbackId" name="feedbackId">
                        <input type="hidden" id="editRating" name="rating" value="5">

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Shelter:</label>
                                <p class="font-semibold" id="formShelterName" style="color: #2B2B2B;"></p>
                            </div>
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Submitted Date:</label>
                                <p class="font-semibold" id="formSubmittedDate" style="color: #2B2B2B;"></p>
                            </div>
                        </div>
                        <h4 class="font-bold pt-2 border-t text-lg" style="border-color: #E5E5E5; color: #2F5D50;">Your Feedback (Editable)</h4>
                        <div>
                            <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Rating:</label>
                            <div class="flex space-x-2" id="ratingStars">
                                <i class="fas fa-star rating-star text-3xl" data-rating="1" onclick="updateFormRating(1)"></i>
                                <i class="fas fa-star rating-star text-3xl" data-rating="2" onclick="updateFormRating(2)"></i>
                                <i class="fas fa-star rating-star text-3xl" data-rating="3" onclick="updateFormRating(3)"></i>
                                <i class="fas fa-star rating-star text-3xl" data-rating="4" onclick="updateFormRating(4)"></i>
                                <i class="fas fa-star rating-star text-3xl" data-rating="5" onclick="updateFormRating(5)"></i>
                            </div>
                            <p class="text-xs text-gray-500 mt-1">Click on stars to change your rating</p>
                        </div>
                        <div>
                            <label for="feedbackComment" class="block text-sm font-medium" style="color: #2B2B2B;">Comment:</label>
                            <textarea id="feedbackComment" name="comment" rows="5" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Share your experience with this shelter..." required></textarea>
                            <p class="text-xs text-gray-500 mt-1">Your feedback helps other adopters make informed decisions.</p>
                        </div>

                        <div class="flex justify-end pt-4 space-x-3">
                            <button type="button" onclick="closeModal('editModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                                Cancel
                            </button>
                            <button type="submit" class="px-6 py-2 rounded-xl text-white font-medium hover:bg-[#24483E] transition duration-150 shadow-md" style="background-color: #2F5D50;" id="submitEditBtn">
                                Save Changes
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Delete Modal -->
        <div id="deleteModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-md mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #B84A4A;">Confirm Deletion</h3>
                    <button onclick="closeModal('deleteModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="text-gray-700">
                    <p class="mb-4 text-lg" style="color: #2B2B2B;">Are you sure you want to delete your feedback for <strong id="deleteShelterName" style="color: #2B2B2B;"></strong>?</p>
                    <p class="mb-6 text-sm italic text-white font-medium p-3 rounded-lg border" style="background-color: #B84A4A; border-color: #B84A4A;">
                        This action cannot be undone. Your rating and comment will be permanently removed.
                    </p>
                </div>
                <div class="flex justify-end space-x-3 pt-4">
                    <button onclick="closeModal('deleteModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Cancel
                    </button>
                    <button id="confirmDeleteBtn" class="px-5 py-2 rounded-xl text-white font-semibold hover:bg-red-700 transition duration-200 shadow-md" style="background-color: #B84A4A;">
                        Yes, Delete Feedback
                    </button>
                </div>
            </div>
        </div>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
                        // =======================================================
                        // Configuration
                        // =======================================================
                        var ITEMS_PER_PAGE = 10;
                        var currentPage = 1;
                        var currentRatingFilter = 'all';
                        var currentFeedbackId = null;

                        // Debug flag
                        var DEBUG = false;

                        // Track AJAX requests
                        var activeAjaxRequests = 0;

                        // =======================================================
                        // 1. MODAL FUNCTIONS
                        // =======================================================
                        function openEditModal(feedbackId) {
                            if (DEBUG)
                                console.log('openEditModal called:', feedbackId);
                            currentFeedbackId = feedbackId;

                            // Get data from table row menggunakan data attributes
                            var feedbackRow = document.querySelector(`.feedback-row[data-feedbackid="${feedbackId}"]`);
                            if (feedbackRow) {
                                var shelterName = feedbackRow.getAttribute('data-sheltername');
                                var date = feedbackRow.getAttribute('data-date');
                                var fullComment = feedbackRow.getAttribute('data-fullcomment');
                                var rating = parseInt(feedbackRow.getAttribute('data-rating'));

                                // Populate form
                                document.getElementById('formShelterName').textContent = shelterName;
                                document.getElementById('formSubmittedDate').textContent = date;
                                document.getElementById('feedbackComment').value = fullComment;
                                document.getElementById('editFeedbackId').value = feedbackId;

                                // Update stars
                                updateFormRating(rating);

                                // Show modal
                                openModal('editModal');
                            } else {
                                alert('Error: Could not find feedback data');
                            }
                        }

                        function openDeleteModal(feedbackId) {
                            if (DEBUG)
                                console.log('openDeleteModal called:', feedbackId);
                            currentFeedbackId = feedbackId;

                            // Get shelter name from table row
                            var feedbackRow = document.querySelector(`.feedback-row[data-feedbackid="${feedbackId}"]`);
                            if (feedbackRow) {
                                var shelterName = feedbackRow.getAttribute('data-sheltername');
                                document.getElementById('deleteShelterName').textContent = shelterName;
                            }

                            // Show modal
                            openModal('deleteModal');
                        }

                        function openModal(modalId) {
                            var modal = document.getElementById(modalId);
                            modal.classList.remove('hidden');
                            setTimeout(function () {
                                modal.classList.remove('opacity-0');
                                modal.querySelector('div:nth-child(1)').classList.remove('scale-95');
                            }, 10);
                        }

                        function closeModal(modalId) {
                            var modal = document.getElementById(modalId);
                            modal.classList.add('opacity-0');
                            modal.querySelector('div:nth-child(1)').classList.add('scale-95');
                            setTimeout(function () {
                                modal.classList.add('hidden');
                            }, 300);
                        }

                        function updateFormRating(rating) {
                            if (DEBUG)
                                console.log('updateFormRating called with rating:', rating);
                            document.getElementById('editRating').value = rating;

                            var stars = document.querySelectorAll('#ratingStars .rating-star');
                            for (var i = 0; i < stars.length; i++) {
                                var star = stars[i];
                                var starRating = parseInt(star.getAttribute('data-rating'));

                                if (starRating <= rating) {
                                    star.style.color = '#FFD700';
                                    star.classList.add('filled');
                                    star.classList.remove('empty');
                                } else {
                                    star.style.color = '#E5E5E5';
                                    star.classList.add('empty');
                                    star.classList.remove('filled');
                                }
                            }
                        }

                        // =======================================================
                        // 2. AJAX Functions - FIXED WITH TIMEOUT
                        // =======================================================
                        function submitEditForm(event) {
                            event.preventDefault();

                            // Disable button untuk elak double click
                            var submitBtn = event.target.querySelector('#submitEditBtn');
                            var originalBtnText = submitBtn ? submitBtn.innerHTML : 'Save Changes';

                            if (submitBtn) {
                                submitBtn.disabled = true;
                                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Saving...';
                            }

                            var formData = new FormData(event.target);
                            var xhr = new XMLHttpRequest();

                            // SET TIMEOUT - INI PENTING!
                            xhr.timeout = 10000; // 10 seconds

                            activeAjaxRequests++;
                            console.log('AJAX Request started (active: ' + activeAjaxRequests + ')');

                            xhr.open('POST', 'FeedbackServlet', true);
                            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

                            xhr.onload = function () {
                                activeAjaxRequests--;
                                console.log('AJAX Request completed (active: ' + activeAjaxRequests + ')');

                                if (submitBtn) {
                                    submitBtn.disabled = false;
                                    submitBtn.innerHTML = originalBtnText;
                                }

                                if (xhr.status === 200) {
                                    try {
                                        var response = JSON.parse(xhr.responseText);
                                        if (response.success) {
                                            alert('✓ Feedback updated successfully!');
                                            closeModal('editModal');
                                            setTimeout(function () {
                                                location.reload();
                                            }, 800);
                                        } else {
                                            alert('✗ Error: ' + response.message);
                                        }
                                    } catch (e) {
                                        console.error('JSON Parse Error:', e);
                                        alert('Server returned invalid response.');
                                    }
                                } else {
                                    alert('Network error. Status: ' + xhr.status);
                                }
                            };

                            xhr.ontimeout = function () {
                                activeAjaxRequests--;
                                console.warn('AJAX Request timeout after 10s (active: ' + activeAjaxRequests + ')');

                                if (submitBtn) {
                                    submitBtn.disabled = false;
                                    submitBtn.innerHTML = originalBtnText;
                                }
                                alert('Request timeout. Please try again.');
                            };

                            xhr.onerror = function () {
                                activeAjaxRequests--;
                                console.error('AJAX Request network error (active: ' + activeAjaxRequests + ')');

                                if (submitBtn) {
                                    submitBtn.disabled = false;
                                    submitBtn.innerHTML = originalBtnText;
                                }
                                alert('Network error occurred.');
                            };

                            var encodedData = new URLSearchParams(formData).toString();
                            xhr.send(encodedData);
                            return false;
                        }

                        function deleteFeedback(feedbackId) {
                            if (!confirm('Are you sure you want to delete this feedback?'))
                                return;

                            var confirmBtn = document.getElementById('confirmDeleteBtn');
                            var originalBtnText = confirmBtn ? confirmBtn.innerHTML : 'Yes, Delete Feedback';

                            if (confirmBtn) {
                                confirmBtn.disabled = true;
                                confirmBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Deleting...';
                            }

                            var xhr = new XMLHttpRequest();

                            // SET TIMEOUT - INI PENTING!
                            xhr.timeout = 10000; // 10 seconds

                            activeAjaxRequests++;
                            console.log('DELETE Request started (active: ' + activeAjaxRequests + ')');

                            xhr.open('DELETE', 'FeedbackServlet?feedbackId=' + feedbackId, true);

                            xhr.onload = function () {
                                activeAjaxRequests--;
                                console.log('DELETE Request completed (active: ' + activeAjaxRequests + ')');

                                if (confirmBtn) {
                                    confirmBtn.disabled = false;
                                    confirmBtn.innerHTML = originalBtnText;
                                }

                                if (xhr.status === 200) {
                                    try {
                                        var response = JSON.parse(xhr.responseText);
                                        if (response.success) {
                                            alert('✓ Feedback deleted successfully!');
                                            closeModal('deleteModal');
                                            setTimeout(function () {
                                                location.reload();
                                            }, 800);
                                        } else {
                                            alert('✗ Error: ' + response.message);
                                        }
                                    } catch (e) {
                                        console.error('JSON Parse Error:', e);
                                        alert('Server returned invalid response.');
                                    }
                                } else {
                                    alert('Network error. Status: ' + xhr.status);
                                }
                            };

                            xhr.ontimeout = function () {
                                activeAjaxRequests--;
                                console.warn('DELETE Request timeout after 10s (active: ' + activeAjaxRequests + ')');

                                if (confirmBtn) {
                                    confirmBtn.disabled = false;
                                    confirmBtn.innerHTML = originalBtnText;
                                }
                                alert('Request timeout. Please try again.');
                            };

                            xhr.onerror = function () {
                                activeAjaxRequests--;
                                console.error('DELETE Request network error (active: ' + activeAjaxRequests + ')');

                                if (confirmBtn) {
                                    confirmBtn.disabled = false;
                                    confirmBtn.innerHTML = originalBtnText;
                                }
                                alert('Network error occurred.');
                            };

                            xhr.send();
                        }

                        // =======================================================
                        // 3. Filtering and Pagination Functions
                        // =======================================================
                        function filterTable() {
                            var searchTerm = document.getElementById('searchInput').value.toLowerCase();
                            var rows = document.querySelectorAll('.feedback-row');
                            var visibleCount = 0;

                            for (var i = 0; i < rows.length; i++) {
                                var row = rows[i];
                                var shelterName = row.getAttribute('data-sheltername').toLowerCase();
                                var rating = row.getAttribute('data-rating');
                                var shouldShow = true;

                                if (searchTerm && !shelterName.includes(searchTerm)) {
                                    shouldShow = false;
                                }

                                if (currentRatingFilter !== 'all' && rating !== currentRatingFilter) {
                                    shouldShow = false;
                                }

                                row.style.display = shouldShow ? '' : 'none';
                                if (shouldShow)
                                    visibleCount++;
                            }

                            updatePaginationInfo(visibleCount);
                        }

                        function updatePaginationInfo(visibleCount) {
                            var start = Math.min(visibleCount, (currentPage - 1) * ITEMS_PER_PAGE + 1);
                            var end = Math.min(visibleCount, currentPage * ITEMS_PER_PAGE);

                            document.getElementById('total-items').textContent = visibleCount;
                            document.getElementById('start-index').textContent = start;
                            document.getElementById('end-index').textContent = end;

                            document.getElementById('prev-btn').disabled = currentPage === 1;
                            document.getElementById('next-btn').disabled = currentPage * ITEMS_PER_PAGE >= visibleCount;
                        }

                        function updateFilterButtonStyles() {
                            var filterButtons = document.querySelectorAll('.filter-btn');

                            for (var i = 0; i < filterButtons.length; i++) {
                                var btn = filterButtons[i];
                                var btnRating = btn.getAttribute('data-rating');

                                // Reset classes
                                btn.className = 'px-5 py-2 rounded-full text-sm font-medium transition duration-150 filter-btn';

                                if (btnRating === currentRatingFilter) {
                                    if (btnRating === 'all') {
                                        btn.classList.add('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                    } else {
                                        btn.classList.add('star-filter', 'shadow-md', 'active-filter');
                                    }
                                } else {
                                    btn.classList.add('border', 'hover:bg-[#F6F3E7]');
                                    if (btnRating === 'all') {
                                        btn.classList.add('border-[#2F5D50]', 'text-[#2F5D50]');
                                    } else {
                                        btn.classList.add('border-[#FFD700]', 'text-[#2B2B2B]');
                                    }
                                }
                            }
                        }

                        // =======================================================
                        // 4. IMAGE LOADING HANDLER - FIXED VERSION
                        // =======================================================
                        function handleAllImagesLoaded() {
                            return new Promise(function (resolve) {
                                var images = document.querySelectorAll('img');
                                var totalImages = images.length;
                                var loadedCount = 0;

                                if (totalImages === 0) {
                                    resolve();
                                    return;
                                }

                                // Check each image
                                images.forEach(function (img) {
                                    if (img.complete) {
                                        loadedCount++;
                                    } else {
                                        img.addEventListener('load', imageLoaded);
                                        img.addEventListener('error', imageLoaded);
                                    }
                                });

                                // Check initial state
                                if (loadedCount === totalImages) {
                                    resolve();
                                    return;
                                }

                                // Fallback timeout
                                var timeoutId = setTimeout(function () {
                                    console.warn('Image loading timeout - forcing continue');
                                    resolve();
                                }, 3000);

                                function imageLoaded() {
                                    loadedCount++;
                                    this.removeEventListener('load', imageLoaded);
                                    this.removeEventListener('error', imageLoaded);

                                    if (loadedCount === totalImages) {
                                        clearTimeout(timeoutId);
                                        resolve();
                                    }
                                }
                            });
                        }

                        // =======================================================
                        // 5. FORCE STOP LOADING INDICATOR - PENTING!
                        // =======================================================
                        function forceStopLoadingIndicator() {
                            console.log('Force stopping loading indicator...');

                            try {
                                // Method 1: Use window.stop() if available
                                if (window.stop && typeof window.stop === 'function') {
                                    window.stop();
                                }

                                // Method 2: Mark page as loaded
                                document.documentElement.setAttribute('data-page-loaded', 'true');

                                // Method 3: Stop any animations/transitions
                                document.body.classList.add('page-loaded-complete');

                                console.log('Loading indicator stopped successfully');
                            } catch (e) {
                                console.warn('Error stopping loading indicator:', e);
                            }
                        }

                        // =======================================================
                        // 6. Event Listeners Setup
                        // =======================================================
                        document.addEventListener('DOMContentLoaded', function () {
                            if (DEBUG)
                                console.log('DOM loaded, setting up event listeners');

                            // Auto-hide messages after 5 seconds
                            setTimeout(function () {
                                var messages = document.querySelectorAll('.fixed.top-4');
                                messages.forEach(function (msg) {
                                    msg.style.display = 'none';
                                });
                            }, 5000);

                            // Search input
                            var searchInput = document.getElementById('searchInput');
                            if (searchInput) {
                                searchInput.addEventListener('input', function () {
                                    currentPage = 1;
                                    filterTable();
                                });
                            }

                            // Filter buttons
                            var filterButtons = document.querySelectorAll('.filter-btn');
                            filterButtons.forEach(function (btn) {
                                btn.addEventListener('click', function (e) {
                                    currentRatingFilter = e.target.getAttribute('data-rating');
                                    currentPage = 1;
                                    updateFilterButtonStyles();
                                    filterTable();
                                });
                            });

                            // Pagination buttons
                            var prevBtn = document.getElementById('prev-btn');
                            var nextBtn = document.getElementById('next-btn');

                            if (prevBtn) {
                                prevBtn.addEventListener('click', function () {
                                    if (currentPage > 1) {
                                        currentPage--;
                                        filterTable();
                                    }
                                });
                            }

                            if (nextBtn) {
                                nextBtn.addEventListener('click', function () {
                                    var rows = document.querySelectorAll('.feedback-row');
                                    var visibleCount = 0;
                                    for (var i = 0; i < rows.length; i++) {
                                        if (rows[i].style.display !== 'none')
                                            visibleCount++;
                                    }

                                    var totalPages = Math.ceil(visibleCount / ITEMS_PER_PAGE);
                                    if (currentPage < totalPages) {
                                        currentPage++;
                                        filterTable();
                                    }
                                });
                            }

                            // Delete button event listener
                            var confirmDeleteBtn = document.getElementById('confirmDeleteBtn');
                            if (confirmDeleteBtn) {
                                confirmDeleteBtn.addEventListener('click', function () {
                                    deleteFeedback(currentFeedbackId);
                                });
                            }

                            // Initial setup
                            updateFilterButtonStyles();
                            filterTable();

                            // Handle image loading
                            handleAllImagesLoaded().then(function () {
                                console.log('All images processed');
                            }).catch(function (error) {
                                console.warn('Image loading error:', error);
                            });

                            if (DEBUG)
                                console.log('Event listeners setup complete');
                        });

                        // =======================================================
                        // 7. WINDOW LOAD EVENT - UTAMA UNTUK STOP LOADING ICON
                        // =======================================================
                        window.addEventListener('load', function () {
                            console.log('Window load event fired - page fully loaded');

                            // Wait a bit then force stop loading
                            setTimeout(function () {
                                forceStopLoadingIndicator();

                                // Check if any AJAX still pending
                                if (activeAjaxRequests > 0) {
                                    console.warn('Still ' + activeAjaxRequests + ' active AJAX requests');
                                }
                            }, 500);
                        });

                        // =======================================================
                        // 8. FALLBACK TIMEOUT - JIKA WINDOW.LOAD TAK TRIGGER
                        // =======================================================
                        setTimeout(function () {
                            if (!document.documentElement.hasAttribute('data-page-loaded')) {
                                console.warn('Fallback: Forcing page load after 5 seconds');
                                forceStopLoadingIndicator();
                            }
                        }, 5000);

                        // =======================================================
                        // 9. Make functions available globally
                        // =======================================================
                        window.openEditModal = openEditModal;
                        window.openDeleteModal = openDeleteModal;
                        window.closeModal = closeModal;
                        window.updateFormRating = updateFormRating;
        </script>
    </body>
</html>