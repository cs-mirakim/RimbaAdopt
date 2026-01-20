<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.ShelterDAO" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="com.rimba.adopt.dao.UsersDao" %>
<%@ page import="com.rimba.adopt.util.DatabaseConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="com.rimba.adopt.dao.FeedbackDAO" %>
<%@ page import="com.rimba.adopt.model.Users" %>

<%
    // Debug: Check session
    System.out.println("DEBUG: Starting shelter_info.jsp");
    
    // Check if user is logged in and is adopter
    if (!SessionUtil.isLoggedIn(session)) {
        System.out.println("DEBUG: User not logged in, redirecting to index.jsp");
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isAdopter(session)) {
        System.out.println("DEBUG: User is not adopter, redirecting to index.jsp");
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Get shelter ID from parameter
    String shelterIdParam = request.getParameter("id");
    System.out.println("DEBUG: shelterIdParam = " + shelterIdParam);
    
    int shelterId = 0;
    Shelter shelter = null;
    double avgRating = 0.0;
    int reviewCount = 0;
    int[] ratingDistribution = new int[5];
    int currentUserId = 0;
    
    // Get current user ID
    Users currentUser = (Users) session.getAttribute("user");
    if (currentUser != null) {
        currentUserId = currentUser.getUserId();
        System.out.println("DEBUG: Current user ID = " + currentUserId);
    }
    
    if (shelterIdParam != null && !shelterIdParam.isEmpty()) {
        try {
            shelterId = Integer.parseInt(shelterIdParam);
            System.out.println("DEBUG: Parsed shelterId = " + shelterId);
            
            // Try multiple ways to get shelter data
            Connection conn = null;
            try {
                conn = DatabaseConnection.getConnection();
                ShelterDAO shelterDAO = new ShelterDAO();
                FeedbackDAO feedbackDAO = new FeedbackDAO();
                
                // Try with new method first
                shelter = shelterDAO.getShelterWithRating(shelterId);
                System.out.println("DEBUG: After getShelterWithRating(), shelter = " + (shelter != null ? "found" : "null"));
                
                if (shelter == null) {
                    // Fallback to old method
                    System.out.println("DEBUG: Falling back to getShelterById()");
                    shelter = shelterDAO.getShelterById(shelterId);
                    System.out.println("DEBUG: After getShelterById(), shelter = " + (shelter != null ? "found" : "null"));
                }
                
                // Get rating stats from FeedbackDAO
                avgRating = feedbackDAO.getAverageRatingByShelterId(shelterId);
                reviewCount = feedbackDAO.getFeedbackCountByShelterId(shelterId);
                ratingDistribution = feedbackDAO.getRatingDistributionByShelterId(shelterId);
                
                System.out.println("DEBUG: Rating stats - avgRating = " + avgRating + ", reviewCount = " + reviewCount);
                System.out.println("DEBUG: Rating distribution: " + java.util.Arrays.toString(ratingDistribution));
                
            } catch (Exception e) {
                System.err.println("ERROR getting shelter data: " + e.getMessage());
                e.printStackTrace();
            } finally {
                if (conn != null) {
                    try { conn.close(); } catch (SQLException e) {}
                }
            }
            
            if (shelter == null) {
                System.out.println("DEBUG: Shelter not found, redirecting to shelter_list.jsp");
                response.sendRedirect("shelter_list.jsp");
                return;
            }
            
        } catch (NumberFormatException e) {
            System.err.println("ERROR: Invalid shelter ID format: " + shelterIdParam);
            response.sendRedirect("shelter_list.jsp");
            return;
        }
    } else {
        System.out.println("DEBUG: No shelter ID parameter, redirecting to shelter_list.jsp");
        response.sendRedirect("shelter_list.jsp");
        return;
    }
    
    // Get available pets for this shelter
    PetsDAO petsDAO = new PetsDAO();
    List<Pets> pets = new ArrayList<Pets>();
    try {
        pets = petsDAO.getAvailablePetsByShelter(shelterId);
        System.out.println("DEBUG: Found " + pets.size() + " available pets");
    } catch (SQLException e) {
        System.err.println("ERROR getting pets: " + e.getMessage());
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
            .star-selector {
                font-size: 32px;
                margin: 10px 0;
                cursor: pointer;
            }
            .select-star {
                color: #ddd;
                margin-right: 5px;
                transition: color 0.2s;
            }
            .select-star:hover,
            .select-star.active {
                color: #f39c12;
            }
            #selected-rating-text {
                color: #7f8c8d;
                font-style: italic;
                margin-top: 5px;
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
                        <a href="shelter_list.jsp" class="flex items-center text-[#2F5D50] hover:text-[#24483E]">
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
                                        <% 
                                        // Generate stars based on average rating
                                        int fullStars = (int) avgRating;
                                        boolean hasHalfStar = (avgRating - fullStars) >= 0.5;
                                        
                                        for (int i = 1; i <= 5; i++) {
                                            if (i <= fullStars) {
                                                out.print("<i class='fas fa-star'></i>");
                                            } else if (i == fullStars + 1 && hasHalfStar) {
                                                out.print("<i class='fas fa-star-half-alt'></i>");
                                            } else {
                                                out.print("<i class='far fa-star'></i>");
                                            }
                                        }
                                        %>
                                    </div>
                                    <div>
                                        <span id="averageRating" class="text-2xl font-bold text-[#2B2B2B]"><%= String.format("%.1f", avgRating) %></span>
                                        <span id="reviewCount" class="text-[#888] ml-1">(<%= reviewCount %> <%= reviewCount == 1 ? "review" : "reviews" %>)</span>
                                    </div>
                                </div>

                                <!-- Rating Distribution -->
                                <div id="ratingDistribution">
                                    <%
                                    int totalReviews = 0;
                                    for (int count : ratingDistribution) {
                                        totalReviews += count;
                                    }
                                    
                                    for (int i = 5; i >= 1; i--) {
                                        int count = ratingDistribution[i-1];
                                        double percentage = totalReviews > 0 ? (count * 100.0 / totalReviews) : 0;
                                    %>
                                    <div class="mb-4">
                                        <div class="flex items-center justify-between mb-1">
                                            <span class="text-sm"><%= i %> star<%= i != 1 ? "s" : "" %></span>
                                            <span class="text-sm font-medium"><%= count %></span>
                                        </div>
                                        <div class="progress-bar">
                                            <div class="progress-fill" style="width: <%= percentage %>%"></div>
                                        </div>
                                    </div>
                                    <%
                                    }
                                    %>
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
                        if (pets.isEmpty()) { 
                        %>
                        <div class="col-span-3 text-center py-8">
                            <i class="fas fa-paw text-4xl text-[#E5E5E5] mb-4"></i>
                            <p class="text-[#888]">No pets available for adoption at this shelter.</p>
                        </div>
                        <% 
                        } else {
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
                        <% 
                            } 
                        } 
                        %>
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
                    <div id="reviewsContainer">
                        <!-- Reviews will be loaded by JavaScript -->
                        <div class="text-center py-8">
                            <i class="fas fa-spinner fa-spin text-4xl text-[#2F5D50] mb-4"></i>
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

                            <button id="nextReviewPage" class="p-3 rounded-lg border border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7] disabled:opacity-50 disabled:cursor-not-allowed">
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
                    <input type="hidden" name="action" value="submitFeedback">
                    <input type="hidden" name="adopterId" value="<%= currentUserId %>">
                    <!-- Tambah flag untuk bypass check -->
                    <input type="hidden" name="forceSubmit" value="true">
                    
                    <div class="mb-6">
                        <label class="block text-[#2B2B2B] mb-3 font-medium">Your Rating:</label>
                        <div class="star-selector">
                            <span class="select-star" data-value="1">☆</span>
                            <span class="select-star" data-value="2">☆</span>
                            <span class="select-star" data-value="3">☆</span>
                            <span class="select-star" data-value="4">☆</span>
                            <span class="select-star" data-value="5">☆</span>
                        </div>
                        <p id="selected-rating-text">Select a star rating</p>
                        <input type="hidden" id="selectedRating" name="rating" value="0">
                    </div>

                    <div class="mb-6">
                        <label for="reviewerName" class="block text-[#2B2B2B] mb-2 font-medium">Your Name</label>
                        <input type="text" id="reviewerName" name="reviewerName" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89] bg-gray-50" 
                               value="<%= currentUser != null ? currentUser.getName() : "" %>" readonly>
                    </div>

                    <div class="mb-6">
                        <label for="reviewComment" class="block text-[#2B2B2B] mb-2 font-medium">Your Review</label>
                        <textarea id="reviewComment" name="comment" rows="5" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" 
                                  placeholder="Share your experience with this shelter..."></textarea>
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
            const currentUserId = <%= currentUserId %>;
            
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
            const selectedRatingInput = document.getElementById('selectedRating');
            const selectedRatingText = document.getElementById('selected-rating-text');

            // Star selector functionality
            function updateStarSelector(rating) {
                const starRatingElements = document.querySelectorAll('.select-star');
                starRatingElements.forEach(star => {
                    const starValue = parseInt(star.getAttribute('data-value'));
                    if (starValue <= rating) {
                        star.textContent = '★';
                        star.classList.add('active');
                    } else {
                        star.textContent = '☆';
                        star.classList.remove('active');
                    }
                });
            }

            function updateRatingText(rating) {
                const ratingPhrases = [
                    "Select a star rating",
                    "Poor",
                    "Fair",
                    "Good",
                    "Very Good",
                    "Excellent"
                ];
                if (selectedRatingText) {
                    selectedRatingText.textContent = ratingPhrases[rating];
                }
            }

            // Initialize
            document.addEventListener('DOMContentLoaded', function () {
                loadReviews();
                attachEventListeners();
                
                // Initialize star selector events
                const starRatingElements = document.querySelectorAll('.select-star');
                if (starRatingElements) {
                    starRatingElements.forEach(star => {
                        star.addEventListener('click', function() {
                            selectedRating = parseInt(this.getAttribute('data-value'));
                            updateStarSelector(selectedRating);
                            updateRatingText(selectedRating);
                            if (selectedRatingInput) {
                                selectedRatingInput.value = selectedRating.toString();
                            }
                        });
                    });
                }
            });

            // Load reviews for current page
            function loadReviews() {
                console.log("DEBUG: Loading reviews for page " + currentReviewPage);

                fetch('FeedbackServlet?action=getFeedback&shelterId=' + shelterId + '&page=' + currentReviewPage + '&pageSize=' + reviewsPerPage)
                    .then(function(response) {
                        console.log("DEBUG: Response status: " + response.status);
                        if (!response.ok) {
                            throw new Error('Network response was not ok');
                        }
                        return response.json();
                    })
                    .then(function(data) {
                        console.log("DEBUG: Received data:", data);
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

            // Update renderReviews() function:
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
                    reviewCard.className = 'feedback-card bg-[#F9F9F9] p-6 rounded-xl mb-4';

                    // Generate star HTML
                    var starsHTML = '';
                    for (var j = 1; j <= 5; j++) {
                        if (j <= review.rating) {
                            starsHTML += '<i class="fas fa-star text-yellow-500"></i>';
                        } else {
                            starsHTML += '<i class="far fa-star text-gray-300"></i>';
                        }
                    }

                    // Format date
                    var dateStr = '';
                    if (review.created_at) {
                        var date = new Date(review.created_at);
                        dateStr = date.toLocaleDateString('en-US', { 
                            year: 'numeric', 
                            month: 'short', 
                            day: 'numeric' 
                        });
                    }

                    reviewCard.innerHTML =
                        '<div class="flex justify-between items-start mb-4">' +
                        '<div>' +
                        '<h4 class="font-bold text-[#2B2B2B] mb-1">' + (review.adopter_name || 'Anonymous') + '</h4>' +
                        '<div class="flex items-center mt-1">' +
                        '<div class="star-rating mr-3">' +
                        starsHTML +
                        '</div>' +
                        '<span class="text-sm text-gray-600">' + review.rating + '/5</span>' +
                        '</div>' +
                        '</div>' +
                        '<span class="text-[#888] text-sm">' + dateStr + '</span>' +
                        '</div>' +
                        '<div class="mb-4">' +
                        '<p class="text-[#666]">' + (review.comment || 'No comment') + '</p>' +
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
                if (feedbackModal) {
                    // Reset form
                    selectedRating = 0;
                    if (selectedRatingInput) {
                        selectedRatingInput.value = "0";
                    }
                    updateStarSelector(0);
                    updateRatingText(0);
                    const reviewComment = document.getElementById('reviewComment');
                    if (reviewComment) reviewComment.value = '';
                    
                    feedbackModal.style.display = 'flex';
                }
            }

            // Close feedback modal
            function closeFeedbackModal() {
                if (feedbackModal) {
                    feedbackModal.style.display = 'none';
                }
            }

            // Handle review form submission - SIMPLE VERSION
            // Dalam fungsi handleReviewSubmit di shelter_info.jsp
            function handleReviewSubmit(e) {
                e.preventDefault();

                const rating = document.getElementById('selectedRating')?.value;
                const comment = document.getElementById('reviewComment')?.value.trim();

                if (!rating || parseInt(rating) === 0) {
                    alert('Please select a rating');
                    return;
                }

                if (!comment) {
                    alert('Please enter your review');
                    return;
                }

                const formData = new FormData();
                formData.append('action', 'submitFeedback');
                formData.append('shelterId', shelterId.toString());
                formData.append('adopterId', currentUserId.toString());
                formData.append('rating', rating);
                formData.append('comment', comment);
                formData.append('forceSubmit', 'true'); // Ini yang penting!

                fetch('FeedbackServlet', {
                    method: 'POST',
                    body: formData
                })
                .then(function(response) {
                    return response.json();
                })
                .then(function(data) {
                    if (data.success) {
                        alert('Review submitted successfully!');
                        closeFeedbackModal();
                        // Reload page to update everything
                        location.reload();
                    } else {
                        alert('Error: ' + data.message);
                    }
                })
                .catch(function(error) {
                    console.error('Error:', error);
                    alert('Failed to submit review. Please try again.');
                });
            }

            // Alternative: Direct submission without checking
            function submitDirectReview(rating, comment) {
                const directFormData = new FormData();
                directFormData.append('shelterId', shelterId.toString());
                directFormData.append('adopterId', currentUserId.toString());
                directFormData.append('rating', rating);
                directFormData.append('comment', comment);
                
                // Use a different endpoint or direct AJAX
                fetch('submit_review_direct.jsp', {
                    method: 'POST',
                    body: directFormData
                })
                .then(function(response) {
                    if (response.ok) {
                        alert('Review submitted successfully!');
                        closeFeedbackModal();
                        location.reload();
                    } else {
                        alert('Failed to submit review. Please try again.');
                    }
                })
                .catch(function(error) {
                    console.error('Error:', error);
                    alert('Network error. Please try again.');
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

                // Review form submission
                if (reviewForm) {
                    reviewForm.addEventListener('submit', handleReviewSubmit);
                }
            }
        </script>

    </body>
</html>