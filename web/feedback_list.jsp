<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.FeedbackDAO" %>
<%@ page import="com.rimba.adopt.model.Feedback" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>

<%
    // Check if user is logged in and is adopter
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isAdopter(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Get adopter ID
    int adopterId = SessionUtil.getUserId(session);
    FeedbackDAO feedbackDAO = new FeedbackDAO();

    // Initialize variables - GUNA SYNTAX JAVA 5
    List feedbackList = new ArrayList();
    int totalCount = 0;
    int[] ratingCounts = new int[6]; // index 0 not used, 1-5 for ratings

    // Get feedback data for this adopter
    try {
        feedbackList = feedbackDAO.getFeedbackByAdopterId(adopterId);
        totalCount = feedbackList.size();

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
    } catch (Exception e) {
        e.printStackTrace();
    }
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
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7] text-main">
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
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary" data-rating="all">All (<%= totalCount%>)</button>
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
                            <%
                                int counter = 0;
                                for (int i = 0; i < feedbackList.size(); i++) {
                                    counter++;
                                    Object[] feedback = (Object[]) feedbackList.get(i);
                                    Integer feedbackId = (Integer) feedback[0];
                                    String shelterName = (String) feedback[1];
                                    Integer rating = (Integer) feedback[2];
                                    String comment = (String) feedback[3];
                                    Timestamp createdAt = (Timestamp) feedback[4];
                                    String shelterLogo = (String) feedback[5];

                                    // Format date
                                    String formattedDate = createdAt.toString().split(" ")[0];
                                    String truncatedComment = comment.length() > 80 ? comment.substring(0, 80) + "..." : comment;

                                    // Generate stars HTML
                                    StringBuffer starsHtml = new StringBuffer();
                                    for (int j = 1; j <= 5; j++) {
                                        if (j <= rating) {
                                            starsHtml.append("<i class=\"fas fa-star star-display\"></i>");
                                        } else {
                                            starsHtml.append("<i class=\"far fa-star\" style=\"color: #E5E5E5;\"></i>");
                                        }
                                    }
                            %>
                            <tr class="hover:bg-gray-50 transition duration-100" data-rating="<%= rating%>">
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;"><%= counter%></td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="flex-shrink-0 h-10 w-10">
                                            <img class="h-10 w-10 rounded-full object-cover" src="<%= shelterLogo != null ? shelterLogo : "https://via.placeholder.com/40x40?text=Shelter"%>" alt="<%= shelterName%>" onerror="this.src='https://via.placeholder.com/40x40?text=Shelter'">
                                        </div>
                                        <div class="ml-4">
                                            <div class="text-sm font-medium" style="color: #2B2B2B;"><%= shelterName%></div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center space-x-1">
                                        <%= starsHtml.toString()%>
                                    </div>
                                </td>
                                <td class="px-6 py-4 text-sm max-w-xs" style="color: #2B2B2B;">
                                    <%= truncatedComment%>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;"><%= formattedDate%></td>
                                <td class="px-6 py-4 whitespace-nowrap text-center">
                                    <div class="flex flex-col items-center space-y-2">
                                        <button onclick="openEditModal(<%= feedbackId%>)" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View/Edit</button>
                                        <button onclick="openDeleteModal(<%= feedbackId%>)" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-red-700" style="background-color: #B84A4A;">Delete</button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>

                            <% if (feedbackList.isEmpty()) { %>
                            <tr>
                                <td colspan="6" class="px-6 py-8 text-center text-gray-500">
                                    <i class="fas fa-comment-slash text-4xl mb-2"></i>
                                    <p class="text-lg">No feedback found.</p>
                                    <p class="text-sm">You haven't submitted any feedback to shelters yet.</p>
                                </td>
                            </tr>
                            <% }%>
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
                    <!-- FORM YANG BETUL - SUBMIT DIRECT KE SERVLET -->
                    <form id="editForm" method="POST" action="FeedbackServlet" class="space-y-4">
                        <!-- HIDDEN INPUTS -->
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

                        <!-- BUTTONS -->
                        <div class="flex justify-end pt-4 space-x-3">
                            <button type="button" onclick="closeModal('editModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                                Cancel
                            </button>
                            <button type="submit" class="px-6 py-2 rounded-xl text-white font-medium hover:bg-[#24483E] transition duration-150 shadow-md" style="background-color: #2F5D50;">
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
                        var DEBUG = true;

                        // =======================================================
                        // 1. MODAL FUNCTIONS
                        // =======================================================
                        function openEditModal(feedbackId) {
                            if (DEBUG)
                                console.log('openEditModal called:', feedbackId);

                            currentFeedbackId = feedbackId;

                            // Get data from table row
                            var feedbackRow = findFeedbackRow(feedbackId);
                            if (feedbackRow) {
                                var shelterName = feedbackRow.cells[1].querySelector('.text-sm').textContent;
                                var date = feedbackRow.cells[4].textContent;

                                // Get full comment from original data (not truncated)
                                var commentCell = feedbackRow.cells[3];
                                var comment = commentCell.textContent;

                                // If comment was truncated, we need to get the full version
                                // Since we only have truncated version in table, we'll use what we have
                                if (comment.indexOf('...') !== -1) {
                                    comment = comment.replace('...', '');
                                }

                                // Get rating from data attribute
                                var rating = parseInt(feedbackRow.getAttribute('data-rating'));
                                if (DEBUG)
                                    console.log('Rating from table:', rating);

                                // Populate form
                                document.getElementById('formShelterName').textContent = shelterName;
                                document.getElementById('formSubmittedDate').textContent = date;
                                document.getElementById('feedbackComment').value = comment;
                                document.getElementById('editFeedbackId').value = feedbackId;

                                // Update stars
                                updateFormRating(rating);

                                // Show modal
                                openModal('editModal');
                            }
                        }

                        function openDeleteModal(feedbackId) {
                            if (DEBUG)
                                console.log('openDeleteModal called:', feedbackId);

                            currentFeedbackId = feedbackId;

                            // Get shelter name from table
                            var feedbackRow = findFeedbackRow(feedbackId);
                            if (feedbackRow) {
                                var shelterName = feedbackRow.cells[1].querySelector('.text-sm').textContent;
                                document.getElementById('deleteShelterName').textContent = shelterName;
                            }

                            // Set delete button action
                            document.getElementById('confirmDeleteBtn').onclick = function () {
                                deleteFeedback(feedbackId);
                            };

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

                            // Update hidden input
                            document.getElementById('editRating').value = rating;

                            // Update stars display
                            var stars = document.querySelectorAll('#ratingStars .rating-star');
                            for (var i = 0; i < stars.length; i++) {
                                var star = stars[i];
                                var starRating = parseInt(star.getAttribute('data-rating'));

                                if (starRating <= rating) {
                                    star.style.color = '#FFD700'; // Gold for filled stars
                                    star.classList.add('filled');
                                    star.classList.remove('empty');
                                } else {
                                    star.style.color = '#E5E5E5'; // Light gray for empty stars
                                    star.classList.add('empty');
                                    star.classList.remove('filled');
                                }
                            }
                        }

                        function findFeedbackRow(feedbackId) {
                            var rows = document.querySelectorAll('#feedback-list tr');
                            for (var i = 0; i < rows.length; i++) {
                                var row = rows[i];
                                if (row.cells.length <= 1)
                                    continue; // Skip empty row

                                // Check if any button in this row has this feedbackId
                                var buttons = row.querySelectorAll('button');
                                for (var j = 0; j < buttons.length; j++) {
                                    var button = buttons[j];
                                    var onclickAttr = button.getAttribute('onclick');
                                    if (onclickAttr && onclickAttr.indexOf(feedbackId.toString()) !== -1) {
                                        return row;
                                    }
                                }
                            }
                            return null;
                        }

                        // =======================================================
                        // 2. AJAX Functions (for delete only)
                        // =======================================================
                        function deleteFeedback(feedbackId) {
                            if (DEBUG)
                                console.log('deleteFeedback called:', feedbackId);

                            if (!confirm('Are you sure you want to delete this feedback?')) {
                                return;
                            }

                            var xhr = new XMLHttpRequest();
                            xhr.open('DELETE', 'FeedbackServlet?feedbackId=' + feedbackId, true);

                            xhr.onreadystatechange = function () {
                                if (xhr.readyState === 4) {
                                    if (DEBUG)
                                        console.log('Delete response:', xhr.status, xhr.responseText);

                                    if (xhr.status === 200) {
                                        try {
                                            var response = JSON.parse(xhr.responseText);
                                            if (response.success) {
                                                alert('✓ Feedback deleted successfully!');
                                                closeModal('deleteModal');
                                                location.reload();
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
                                }
                            };

                            xhr.onerror = function () {
                                alert('Network error occurred.');
                            };

                            xhr.send();
                        }

                        // =======================================================
                        // 3. Filtering and Pagination Functions
                        // =======================================================
                        function filterTable() {
                            var searchTerm = document.getElementById('searchInput').value.toLowerCase();
                            var rows = document.querySelectorAll('#feedback-list tr');
                            var visibleCount = 0;

                            for (var i = 0; i < rows.length; i++) {
                                var row = rows[i];
                                if (row.cells.length <= 1)
                                    continue; // Skip empty message row

                                var shelterName = row.cells[1].querySelector('.text-sm').textContent.toLowerCase();
                                var rating = row.getAttribute('data-rating');
                                var shouldShow = true;

                                // Apply search filter
                                if (searchTerm && shelterName.indexOf(searchTerm) === -1) {
                                    shouldShow = false;
                                }

                                // Apply rating filter
                                if (currentRatingFilter !== 'all' && rating !== currentRatingFilter) {
                                    shouldShow = false;
                                }

                                if (shouldShow) {
                                    row.style.display = '';
                                    visibleCount++;
                                } else {
                                    row.style.display = 'none';
                                }
                            }

                            updatePaginationInfo(visibleCount);
                        }

                        function updatePaginationInfo(visibleCount) {
                            var start = Math.min(visibleCount, (currentPage - 1) * ITEMS_PER_PAGE + 1);
                            var end = Math.min(visibleCount, currentPage * ITEMS_PER_PAGE);

                            document.getElementById('total-items').textContent = visibleCount;
                            document.getElementById('start-index').textContent = start;
                            document.getElementById('end-index').textContent = end;

                            // Update button states
                            document.getElementById('prev-btn').disabled = currentPage === 1;
                            document.getElementById('next-btn').disabled = currentPage * ITEMS_PER_PAGE >= visibleCount;

                            // Show/hide empty message
                            var emptyRow = document.querySelector('#feedback-list tr:only-child');
                            if (visibleCount === 0) {
                                if (!emptyRow || emptyRow.cells.length > 1) {
                                    var tbody = document.getElementById('feedback-list');
                                    tbody.innerHTML = '<tr><td colspan="6" class="px-6 py-8 text-center text-gray-500"><i class="fas fa-comment-slash text-4xl mb-2"></i><p class="text-lg">No matching feedback found.</p><p class="text-sm">Try adjusting your filters.</p></td></tr>';
                                }
                            }
                        }

                        function updateFilterButtonStyles() {
                            var filterButtons = document.querySelectorAll('.filter-btn');

                            for (var i = 0; i < filterButtons.length; i++) {
                                var btn = filterButtons[i];
                                var btnRating = btn.getAttribute('data-rating');

                                btn.className = 'px-5 py-2 rounded-full text-sm font-medium transition duration-150 filter-btn';

                                if (btnRating === currentRatingFilter) {
                                    if (btnRating === 'all') {
                                        btn.classList.add('bg-primary', 'text-white', 'shadow-md');
                                    } else {
                                        btn.classList.add('star-filter', 'shadow-md');
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
                        // 4. Event Listeners Setup
                        // =======================================================
                        document.addEventListener('DOMContentLoaded', function () {
                            if (DEBUG)
                                console.log('DOM loaded, setting up event listeners');

                            // Search input
                            document.getElementById('searchInput').addEventListener('input', function () {
                                currentPage = 1;
                                filterTable();
                            });

                            // Filter buttons
                            var filterButtons = document.querySelectorAll('.filter-btn');
                            for (var i = 0; i < filterButtons.length; i++) {
                                filterButtons[i].addEventListener('click', function (e) {
                                    currentRatingFilter = e.target.getAttribute('data-rating');
                                    currentPage = 1;
                                    updateFilterButtonStyles();
                                    filterTable();
                                });
                            }

                            // Pagination buttons
                            document.getElementById('prev-btn').addEventListener('click', function () {
                                if (currentPage > 1) {
                                    currentPage--;
                                    filterTable();
                                }
                            });

                            document.getElementById('next-btn').addEventListener('click', function () {
                                var rows = document.querySelectorAll('#feedback-list tr');
                                var visibleCount = 0;
                                for (var i = 0; i < rows.length; i++) {
                                    if (rows[i].style.display !== 'none' && rows[i].cells.length > 1) {
                                        visibleCount++;
                                    }
                                }

                                var totalPages = Math.ceil(visibleCount / ITEMS_PER_PAGE);
                                if (currentPage < totalPages) {
                                    currentPage++;
                                    filterTable();
                                }
                            });

                            // Initial setup
                            updateFilterButtonStyles();
                            filterTable();

                            if (DEBUG)
                                console.log('Event listeners setup complete');
                        });

                        // Make functions available globally
                        window.openEditModal = openEditModal;
                        window.openDeleteModal = openDeleteModal;
                        window.closeModal = closeModal;
                        window.updateFormRating = updateFormRating;
        </script>
    </body>
</html>