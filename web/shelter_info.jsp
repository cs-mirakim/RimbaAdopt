<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.ShelterDAO" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.SQLException" %>

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
    
    // Get shelter ID from parameter
    String shelterIdParam = request.getParameter("id");
    int shelterId = 0;
    Shelter shelter = null;
    
    if (shelterIdParam != null && !shelterIdParam.isEmpty()) {
        try {
            shelterId = Integer.parseInt(shelterIdParam);
            ShelterDAO shelterDAO = new ShelterDAO();
            shelter = shelterDAO.getShelterById(shelterId);
            
            if (shelter == null) {
                response.sendRedirect("shelter_list.jsp");
                return;
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("shelter_list.jsp");
            return;
        }
    } else {
        response.sendRedirect("shelter_list.jsp");
        return;
    }
    
    // Get available pets for this shelter
    PetsDAO petsDAO = new PetsDAO();
    List<Pets> pets = new ArrayList<Pets>();
    try {
        pets = petsDAO.getAvailablePetsByShelter(shelterId);
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= shelter.getShelterName() %> - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            .feedback-card {
                border-left: 4px solid #2F5D50;
            }
            .star-rating {
                color: #C49A6C;
            }
            .progress-bar {
                height: 8px;
                border-radius: 4px;
                background-color: #E5E5E5;
                overflow: hidden;
            }
            .progress-fill {
                height: 100%;
                background-color: #C49A6C;
                border-radius: 4px;
            }
            .modal-overlay {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: rgba(0, 0, 0, 0.5);
                z-index: 1000;
                justify-content: center;
                align-items: center;
            }
            .modal-content {
                background-color: white;
                border-radius: 12px;
                max-width: 500px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
            }
            body {
                overflow-x: hidden;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Main Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Back Button and Title -->
                <div class="mb-8">
                    <div class="flex items-center justify-between mb-2">
                        <a href="shelter_list.html" class="flex items-center text-[#2F5D50] hover:text-[#24483E]">
                            <i class="fas fa-arrow-left mr-2"></i> Back to Shelters
                        </a>
                        <div class="bg-[#6DBF89] text-[#06321F] px-4 py-2 rounded-full text-sm font-medium">
                            <i class="fas fa-check-circle mr-2"></i> 
                            <% 
                            if ("approved".equals(shelter.getApprovalStatus())) {
                                out.print("Approved Shelter");
                            } else {
                                out.print("Pending Approval");
                            }
                            %>
                        </div>
                    </div>
                    <h1 class="text-3xl font-bold text-[#2F5D50]">Shelter Information</h1>
                </div>

                <!-- Shelter Info Container 1 -->
                <div class="mb-10 p-6 border border-[#E5E5E5] rounded-xl bg-white">
                    <div class="flex flex-col lg:flex-row gap-8">
                        <!-- Left: Shelter Photo and Basic Info -->
                        <div class="lg:w-1/3">
                            <div class="mb-6">
                                <img src="<%= shelter.getPhotoPath() != null ? shelter.getPhotoPath() : "profile_picture/shelter/default.png" %>" 
                                     alt="<%= shelter.getShelterName() %>" 
                                     class="w-full h-64 object-cover rounded-xl">
                            </div>

                            <div class="bg-[#F9F9F9] p-5 rounded-xl">
                                <div class="flex items-center mb-4">
                                    <div id="averageStars" class="star-rating text-2xl mr-3">
                                        <!-- Stars will be loaded by JavaScript -->
                                        <i class="far fa-star"></i>
                                        <i class="far fa-star"></i>
                                        <i class="far fa-star"></i>
                                        <i class="far fa-star"></i>
                                        <i class="far fa-star"></i>
                                    </div>
                                    <div>
                                        <span id="averageRating" class="text-2xl font-bold text-[#2B2B2B]">0.0</span>
                                        <span id="reviewCount" class="text-[#888] ml-1">(0 reviews)</span>
                                    </div>
                                </div>

                                <!-- Rating Distribution -->
                                <div id="ratingDistribution">
                                    <!-- Will be loaded by JavaScript -->
                                </div>

                                <button id="writeReviewBtn" class="w-full py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                                    <i class="fas fa-edit mr-2"></i> Write a Review
                                </button>
                            </div>
                        </div>

                        <!-- Right: Shelter Details -->
                        <div class="lg:w-2/3">
                            <div class="mb-6">
                                <h2 class="text-2xl font-bold text-[#2B2B2B] mb-4"><%= shelter.getShelterName() %></h2>

                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                                    <div class="flex items-start">
                                        <div class="bg-[#F0F7F4] p-3 rounded-lg mr-4">
                                            <i class="fas fa-map-marker-alt text-[#2F5D50] text-lg"></i>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-[#2B2B2B] mb-1">Location</h3>
                                            <p class="text-[#666]"><%= shelter.getShelterAddress() != null ? shelter.getShelterAddress() : "Address not available" %></p>
                                        </div>
                                    </div>

                                    <div class="flex items-start">
                                        <div class="bg-[#F0F7F4] p-3 rounded-lg mr-4">
                                            <i class="fas fa-phone-alt text-[#2F5D50] text-lg"></i>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-[#2B2B2B] mb-1">Contact</h3>
                                            <p class="text-[#666]"><%= shelter.getPhone() != null ? shelter.getPhone() : "N/A" %></p>
                                            <p class="text-[#666]"><%= shelter.getEmail() != null ? shelter.getEmail() : "N/A" %></p>
                                        </div>
                                    </div>

                                    <div class="flex items-start">
                                        <div class="bg-[#F0F7F4] p-3 rounded-lg mr-4">
                                            <i class="fas fa-clock text-[#2F5D50] text-lg"></i>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-[#2B2B2B] mb-1">Operating Hours</h3>
                                            <p class="text-[#666]"><%= shelter.getOperatingHours() != null ? shelter.getOperatingHours() : "Mon-Fri: 9:00 AM - 6:00 PM" %></p>
                                        </div>
                                    </div>

                                    <div class="flex items-start">
                                        <div class="bg-[#F0F7F4] p-3 rounded-lg mr-4">
                                            <i class="fas fa-globe text-[#2F5D50] text-lg"></i>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-[#2B2B2B] mb-1">Website</h3>
                                            <p class="text-[#666]"><%= shelter.getWebsite() != null ? shelter.getWebsite() : "N/A" %></p>
                                        </div>
                                    </div>
                                </div>

                                <div class="bg-white p-6 rounded-xl border border-[#E5E5E5]">
                                    <h3 class="text-xl font-bold text-[#2B2B2B] mb-4">About This Shelter</h3>
                                    <div class="text-[#666] leading-relaxed">
                                        <p><%= shelter.getShelterDescription() != null ? shelter.getShelterDescription() : "No description available." %></p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Container 2: Pets Available Grid -->
                <div class="mb-10 p-6 border border-[#E5E5E5] rounded-xl bg-white">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-2xl font-bold text-[#2B2B2B]">Pets Available for Adoption</h2>
                        <div class="text-sm text-[#888]">
                            <span id="petCount"><%= pets.size() %> pets available</span>
                        </div>
                    </div>

                    <!-- Pets Grid -->
                    <div id="petsGrid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-6">
                        <% 
                        for (Pets pet : pets) { 
                            String petPhoto = pet.getPhotoPath() != null ? pet.getPhotoPath() : "profile_picture/pet/default.png";
                            String breed = pet.getBreed() != null ? pet.getBreed() : "Mixed";
                            String age = pet.getAge() != null ? pet.getAge().toString() + " years" : "N/A";
                            String size = pet.getSize() != null ? pet.getSize() : "N/A";
                            String description = pet.getDescription() != null ? pet.getDescription() : "No description available.";
                        %>
                        <div class="bg-white rounded-xl shadow-lg overflow-hidden border border-[#E5E5E5] hover:shadow-xl transition duration-300">
                            <div class="relative">
                                <img src="<%= petPhoto %>" 
                                     alt="<%= pet.getName() %>" 
                                     class="w-full h-48 object-cover">
                                <div class="absolute top-3 right-3 bg-[#2F5D50] text-white px-3 py-1 rounded-full text-sm font-medium">
                                    Available
                                </div>
                            </div>
                            <div class="p-4">
                                <h3 class="text-xl font-bold text-[#2B2B2B] mb-2"><%= pet.getName() %></h3>
                                <div class="grid grid-cols-2 gap-2 mb-3">
                                    <div>
                                        <p class="text-xs text-[#888]">Species</p>
                                        <p class="font-medium text-sm"><%= pet.getSpecies() %></p>
                                    </div>
                                    <div>
                                        <p class="text-xs text-[#888]">Breed</p>
                                        <p class="font-medium text-sm"><%= breed %></p>
                                    </div>
                                    <div>
                                        <p class="text-xs text-[#888]">Age</p>
                                        <p class="font-medium text-sm"><%= age %></p>
                                    </div>
                                    <div>
                                        <p class="text-xs text-[#888]">Size</p>
                                        <p class="font-medium text-sm"><%= size %></p>
                                    </div>
                                </div>
                                <p class="text-[#666] text-sm mb-4 line-clamp-2"><%= description %></p>
                                <div class="text-center">
                                    <a href="pet_info.jsp?id=<%= pet.getPetId() %>" class="inline-block w-full px-4 py-2 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300 text-sm">
                                        <i class="fas fa-heart mr-1"></i> Adopt <%= pet.getName() %>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <% } %>
                        
                        <% if (pets.isEmpty()) { %>
                        <div class="col-span-3 text-center py-8">
                            <i class="fas fa-paw text-4xl text-[#E5E5E5] mb-4"></i>
                            <p class="text-[#888]">No pets available for adoption at this shelter.</p>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- Container 3: Feedback Section -->
                <div class="p-6 border border-[#E5E5E5] rounded-xl bg-white">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-2xl font-bold text-[#2B2B2B]">Reviews & Feedback</h2>
                        <button id="openFeedbackModal" class="px-5 py-2 bg-[#6DBF89] text-[#06321F] font-medium rounded-lg hover:bg-[#57A677] transition duration-300">
                            <i class="fas fa-plus mr-2"></i> Add Review
                        </button>
                    </div>

                    <!-- Reviews List -->
                    <div id="reviewsContainer" class="space-y-6">
                        <div class="text-center py-8">
                            <i class="fas fa-spinner fa-spin text-2xl text-[#2F5D50] mb-4"></i>
                            <p class="text-[#888]">Loading reviews...</p>
                        </div>
                    </div>

                    <!-- Pagination for Reviews -->
                    <div class="flex justify-center items-center mt-8">
                        <nav class="flex items-center space-x-2">
                            <button id="prevReviewPage" class="p-3 rounded-lg border border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7] disabled:opacity-50 disabled:cursor-not-allowed">
                                <i class="fas fa-chevron-left"></i>
                            </button>

                            <div id="reviewPageNumbers" class="flex space-x-2">
                                <!-- Page numbers will be generated here -->
                            </div>

                            <button id="nextReviewPage" class="p-3 rounded-lg border border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7]">
                                <i class="fas fa-chevron-right"></i>
                            </button>
                        </nav>
                    </div>
                </div>

            </div>
        </main>

        <!-- Feedback Modal -->
        <div id="feedbackModal" class="modal-overlay">
            <div class="modal-content p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold text-[#2B2B2B]">Write a Review</h3>
                    <button id="closeModal" class="text-[#888] hover:text-[#2B2B2B]">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <form id="reviewForm">
                    <input type="hidden" id="shelterId" name="shelterId" value="<%= shelterId %>">
                    
                    <div class="mb-6">
                        <label class="block text-[#2B2B2B] mb-3 font-medium">Rating</label>
                        <div class="flex space-x-2" id="starRating">
                            <i class="far fa-star text-3xl text-[#C49A6C] cursor-pointer rating-star" data-value="1"></i>
                            <i class="far fa-star text-3xl text-[#C49A6C] cursor-pointer rating-star" data-value="2"></i>
                            <i class="far fa-star text-3xl text-[#C49A6C] cursor-pointer rating-star" data-value="3"></i>
                            <i class="far fa-star text-3xl text-[#C49A6C] cursor-pointer rating-star" data-value="4"></i>
                            <i class="far fa-star text-3xl text-[#C49A6C] cursor-pointer rating-star" data-value="5"></i>
                        </div>
                        <input type="hidden" id="selectedRating" name="rating" value="0">
                    </div>

                    <div class="mb-6">
                        <label for="reviewTitle" class="block text-[#2B2B2B] mb-2 font-medium">Review Title</label>
                        <input type="text" id="reviewTitle" name="title" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Summarize your experience">
                    </div>

                    <div class="mb-6">
                        <label for="reviewComment" class="block text-[#2B2B2B] mb-2 font-medium">Your Review</label>
                        <textarea id="reviewComment" name="comment" rows="5" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Share details of your experience with this shelter..."></textarea>
                    </div>

                    <div class="flex justify-end space-x-3">
                        <button type="button" id="cancelReview" class="px-6 py-3 border border-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#F6F3E7]">
                            Cancel
                        </button>
                        <button type="submit" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                            Submit Review
                        </button>
                    </div>
                </form>
            </div>
        </div>

         <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

       
        <script src="includes/sidebar.js"></script>

        <script>
            // Get shelter ID from JSP
            const shelterId = <%= shelterId %>;
            
            // Pagination variables
            let currentReviewPage = 1;
            const reviewsPerPage = 4;
            let selectedRating = 0;
            let totalReviewPages = 1;

            // DOM Elements
            const reviewsContainer = document.getElementById('reviewsContainer');
            const prevReviewPageBtn = document.getElementById('prevReviewPage');
            const nextReviewPageBtn = document.getElementById('nextReviewPage');
            const reviewPageNumbers = document.getElementById('reviewPageNumbers');
            const feedbackModal = document.getElementById('feedbackModal');
            const openFeedbackModalBtn = document.getElementById('openFeedbackModal');
            const writeReviewBtn = document.getElementById('writeReviewBtn');
            const closeModalBtn = document.getElementById('closeModal');
            const cancelReviewBtn = document.getElementById('cancelReview');
            const reviewForm = document.getElementById('reviewForm');
            const starRatingElements = document.querySelectorAll('.rating-star');
            const selectedRatingInput = document.getElementById('selectedRating');
            const averageRatingElement = document.getElementById('averageRating');
            const reviewCountElement = document.getElementById('reviewCount');
            const averageStarsElement = document.getElementById('averageStars');
            const ratingDistributionElement = document.getElementById('ratingDistribution');

            // Initialize
            document.addEventListener('DOMContentLoaded', function () {
                loadRatingStats();
                loadReviews();
                attachEventListeners();
            });

            // Load rating statistics
            function loadRatingStats() {
                fetch('FeedbackServlet?action=getFeedback&shelterId=' + shelterId + '&page=1&pageSize=1')
                    .then(function(response) {
                        return response.json();
                    })
                    .then(function(data) {
                        if (data.success) {
                            updateRatingStats(data.averageRating, data.ratingDistribution, data.totalCount);
                        }
                    })
                    .catch(function(error) {
                        console.error('Error loading rating stats:', error);
                    });
            }

            // Update rating statistics display
            function updateRatingStats(averageRating, ratingDistribution, totalCount) {
                // Update average rating
                if (averageRatingElement) {
                    averageRatingElement.textContent = averageRating.toFixed(1);
                }
                if (reviewCountElement) {
                    reviewCountElement.textContent = '(' + totalCount + ' ' + (totalCount === 1 ? 'review' : 'reviews') + ')';
                }
                
                // Update stars
                if (averageStarsElement) {
                    let starsHTML = '';
                    const fullStars = Math.floor(averageRating);
                    const hasHalfStar = averageRating % 1 >= 0.5;
                    
                    for (let i = 1; i <= 5; i++) {
                        if (i <= fullStars) {
                            starsHTML += '<i class="fas fa-star"></i>';
                        } else if (i === fullStars + 1 && hasHalfStar) {
                            starsHTML += '<i class="fas fa-star-half-alt"></i>';
                        } else {
                            starsHTML += '<i class="far fa-star"></i>';
                        }
                    }
                    averageStarsElement.innerHTML = starsHTML;
                }
                
                // Update rating distribution
                if (ratingDistributionElement) {
                    let distributionHTML = '';
                    const total = ratingDistribution.reduce(function(a, b) { return a + b; }, 0);
                    
                    for (let i = 5; i >= 1; i--) {
                        const count = ratingDistribution[i-1] || 0;
                        const percentage = total > 0 ? (count / total * 100) : 0;
                        
                        distributionHTML += 
                            '<div class="mb-4">' +
                            '<div class="flex items-center justify-between mb-1">' +
                            '<span class="text-sm">' + i + ' star' + (i !== 1 ? 's' : '') + '</span>' +
                            '<span class="text-sm font-medium">' + count + '</span>' +
                            '</div>' +
                            '<div class="progress-bar">' +
                            '<div class="progress-fill" style="width: ' + percentage + '%"></div>' +
                            '</div>' +
                            '</div>';
                    }
                    ratingDistributionElement.innerHTML = distributionHTML;
                }
            }

            // Load reviews for current page
            function loadReviews() {
                fetch('FeedbackServlet?action=getFeedback&shelterId=' + shelterId + '&page=' + currentReviewPage + '&pageSize=' + reviewsPerPage)
                    .then(function(response) {
                        return response.json();
                    })
                    .then(function(data) {
                        if (data.success) {
                            renderReviews(data.feedbackList);
                            updateReviewPagination(data.totalCount, data.currentPage, data.pageSize);
                            totalReviewPages = data.totalPages;
                        } else {
                            console.error('Error loading reviews:', data.message);
                            showNoReviews();
                        }
                    })
                    .catch(function(error) {
                        console.error('Error:', error);
                        showNoReviews();
                    });
            }

            // Show no reviews message
            function showNoReviews() {
                if (reviewsContainer) {
                    reviewsContainer.innerHTML = 
                        '<div class="text-center py-8">' +
                        '<i class="fas fa-comment-slash text-4xl text-[#E5E5E5] mb-4"></i>' +
                        '<p class="text-[#888]">No reviews yet. Be the first to review this shelter!</p>' +
                        '</div>';
                }
            }

            // Render reviews
            function renderReviews(reviews) {
                if (!reviewsContainer) return;
                
                reviewsContainer.innerHTML = '';

                if (!reviews || reviews.length === 0) {
                    showNoReviews();
                    return;
                }

                for (var i = 0; i < reviews.length; i++) {
                    var review = reviews[i];
                    var reviewCard = document.createElement('div');
                    reviewCard.className = 'feedback-card bg-[#F9F9F9] p-6 rounded-xl';
                    
                    // Generate star HTML
                    var starsHTML = '';
                    for (var j = 1; j <= 5; j++) {
                        if (j <= review.rating) {
                            starsHTML += '<i class="fas fa-star"></i>';
                        } else {
                            starsHTML += '<i class="far fa-star"></i>';
                        }
                    }

                    reviewCard.innerHTML =
                        '<div class="flex justify-between items-start mb-4">' +
                        '<div>' +
                        '<div class="flex items-center mt-1">' +
                        '<div class="star-rating mr-3">' +
                        starsHTML +
                        '</div>' +
                        '<span class="text-[#888] text-sm">by ' + (review.adopterName || 'Anonymous') + '</span>' +
                        '</div>' +
                        '</div>' +
                        '<span class="text-[#888] text-sm">' + (review.relativeTime || '') + '</span>' +
                        '</div>' +
                        '<p class="text-[#666] mb-4">' + (review.comment || '') + '</p>' +
                        '<div class="flex justify-between items-center">' +
                        '<button class="text-[#2F5D50] hover:text-[#24483E] text-sm helpful-btn" data-id="' + review.feedbackId + '">' +
                        '<i class="far fa-thumbs-up mr-1"></i> Helpful' +
                        '</button>' +
                        '<button class="text-[#888] hover:text-[#2B2B2B] text-sm report-btn" data-id="' + review.feedbackId + '">' +
                        '<i class="far fa-flag mr-1"></i> Report' +
                        '</button>' +
                        '</div>';

                    reviewsContainer.appendChild(reviewCard);
                }
            }

            // Update review pagination
            function updateReviewPagination(totalCount, currentPage, pageSize) {
                const totalPages = Math.ceil(totalCount / pageSize);

                // Update button states
                if (prevReviewPageBtn) {
                    prevReviewPageBtn.disabled = currentPage === 1;
                }
                if (nextReviewPageBtn) {
                    nextReviewPageBtn.disabled = currentPage === totalPages || totalPages === 0;
                }

                // Generate page number buttons
                if (reviewPageNumbers) {
                    reviewPageNumbers.innerHTML = '';
                    const maxVisiblePages = 5;
                    let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
                    let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

            // Open feedback modal
            function openFeedbackModal() {
                feedbackModal.classList.add('show');
                setTimeout(() => {
                    const modalContent = feedbackModal.querySelector('.modal-content');
                    modalContent.classList.add('show');
                }, 10);
            }

            // Close feedback modal
            function closeFeedbackModal() {
                const modalContent = feedbackModal.querySelector('.modal-content');
                modalContent.classList.remove('show');

                setTimeout(() => {
                    feedbackModal.classList.remove('show');
                    resetReviewForm();
                }, 300);
            }

            // Reset review form
            function resetReviewForm() {
                selectedRating = 0;
                selectedRatingInput.value = "0";

                // Reset stars
                starRatingElements.forEach(star => {
                    star.classList.remove('fas');
                    star.classList.add('far');
                });

                // Reset form fields
                document.getElementById('reviewTitle').value = '';
                document.getElementById('reviewComment').value = '';
            }

            // Handle star rating selection
            function handleStarClick(e) {
                const rating = parseInt(e.target.getAttribute('data-value'));
                selectedRating = rating;
                selectedRatingInput.value = rating.toString();

                // Update star display
                starRatingElements.forEach((star, index) => {
                    if (index < rating) {
                        star.classList.remove('far');
                        star.classList.add('fas');
                    } else {
                        star.classList.remove('fas');
                        star.classList.add('far');
                    }
                });
            }

                    for (let i = startPage; i <= endPage; i++) {
                        const pageBtn = document.createElement('button');
                        pageBtn.className = 'review-page-btn w-10 h-10 rounded-lg border ' + 
                                            (i === currentPage ? 'border-[#2F5D50] bg-[#2F5D50] text-white' : 'border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7]');
                        pageBtn.textContent = i;
                        pageBtn.addEventListener('click', function() {
                            currentReviewPage = i;
                            loadReviews();
                        });
                        reviewPageNumbers.appendChild(pageBtn);
                    }
                }
            }

            // Next review page
            function nextReviewPage() {
                if (currentReviewPage < totalReviewPages) {
                    currentReviewPage++;
                    loadReviews();
                }
            }

            // Previous review page
            function prevReviewPage() {
                if (currentReviewPage > 1) {
                    currentReviewPage--;
                    loadReviews();
                }
            }

            // Open feedback modal
            function openFeedbackModal() {
                // Check if user has already reviewed
                fetch('FeedbackServlet?action=checkReview&shelterId=' + shelterId)
                    .then(function(response) {
                        return response.json();
                    })
                    .then(function(data) {
                        if (data.success && data.hasReviewed) {
                            alert('You have already reviewed this shelter.');
                            return;
                        }
                        
                        if (feedbackModal) {
                            feedbackModal.style.display = 'flex';
                        }
                    })
                    .catch(function(error) {
                        console.error('Error checking review:', error);
                        // Still open modal even if check fails
                        if (feedbackModal) {
                            feedbackModal.style.display = 'flex';
                        }
                    });
            }

            // Close feedback modal
            function closeFeedbackModal() {
                if (feedbackModal) {
                    feedbackModal.style.display = 'none';
                    resetReviewForm();
                }
            }

            // Reset review form
            function resetReviewForm() {
                selectedRating = 0;
                if (selectedRatingInput) {
                    selectedRatingInput.value = "0";
                }

                // Reset stars
                for (var i = 0; i < starRatingElements.length; i++) {
                    var star = starRatingElements[i];
                    star.classList.remove('fas');
                    star.classList.add('far');
                }

                // Reset form fields
                var reviewTitle = document.getElementById('reviewTitle');
                var reviewComment = document.getElementById('reviewComment');
                if (reviewTitle) reviewTitle.value = '';
                if (reviewComment) reviewComment.value = '';
            }

            // Handle star rating selection
            function handleStarClick(e) {
                const rating = parseInt(e.target.getAttribute('data-value'));
                selectedRating = rating;
                if (selectedRatingInput) {
                    selectedRatingInput.value = rating.toString();
                }

                // Update star display
                for (var i = 0; i < starRatingElements.length; i++) {
                    var star = starRatingElements[i];
                    if (i < rating) {
                        star.classList.remove('far');
                        star.classList.add('fas');
                    } else {
                        star.classList.remove('fas');
                        star.classList.add('far');
                    }
                }
            }

            // Handle review form submission
            function handleReviewSubmit(e) {
                e.preventDefault();

                const shelterId = document.getElementById('shelterId').value;
                const rating = document.getElementById('selectedRating').value;
                const title = document.getElementById('reviewTitle').value.trim();
                const comment = document.getElementById('reviewComment').value.trim();

                if (parseInt(rating) === 0) {
                    alert('Please select a rating');
                    return;
                }

                if (!comment) {
                    alert('Please enter your review');
                    return;
                }

                const formData = new FormData();
                formData.append('shelterId', shelterId);
                formData.append('rating', rating);
                if (title) {
                    formData.append('title', title);
                }
                formData.append('comment', comment);

                fetch('FeedbackServlet', {
                    method: 'POST',
                    body: formData
                })
                .then(function(response) {
                    return response.json();
                })
                .then(function(data) {
                    if (data.success) {
                        alert(data.message);
                        closeFeedbackModal();
                        // Reload reviews and rating stats
                        loadReviews();
                        loadRatingStats();
                    } else {
                        alert('Error: ' + data.message);
                    }
                })
                .catch(function(error) {
                    console.error('Error:', error);
                    alert('Failed to submit review. Please try again.');
                });
            }

            // Attach event listeners
            function attachEventListeners() {
                if (prevReviewPageBtn) {
                    prevReviewPageBtn.addEventListener('click', prevReviewPage);
                }
                if (nextReviewPageBtn) {
                    nextReviewPageBtn.addEventListener('click', nextReviewPage);
                }

                if (openFeedbackModalBtn) {
                    openFeedbackModalBtn.addEventListener('click', openFeedbackModal);
                }
                if (writeReviewBtn) {
                    writeReviewBtn.addEventListener('click', openFeedbackModal);
                }
                if (closeModalBtn) {
                    closeModalBtn.addEventListener('click', closeFeedbackModal);
                }
                if (cancelReviewBtn) {
                    cancelReviewBtn.addEventListener('click', closeFeedbackModal);
                }

                // Close modal when clicking outside
                if (feedbackModal) {
                    feedbackModal.addEventListener('click', function(e) {
                        if (e.target === feedbackModal) {
                            closeFeedbackModal();
                        }
                    });
                }

                // Star rating click events
                for (var i = 0; i < starRatingElements.length; i++) {
                    starRatingElements[i].addEventListener('click', handleStarClick);
                }

                // Review form submission
                if (reviewForm) {
                    reviewForm.addEventListener('submit', handleReviewSubmit);
                }
            }
        </script>

    </body>
</html>
