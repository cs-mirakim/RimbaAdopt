<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.ShelterDAO" %>
<%@ page import="com.rimba.adopt.dao.FeedbackDAO" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="java.util.List" %>

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
    
    // Get all approved shelters with ratings
    ShelterDAO shelterDAO = new ShelterDAO();
    List<Shelter> shelters = shelterDAO.getSheltersForPublic();
    
    // Get filter parameters
    String searchTerm = request.getParameter("search");
    String minRatingParam = request.getParameter("minRating");
    double minRating = 0.0;
    
    if (minRatingParam != null && !minRatingParam.trim().isEmpty()) {
        try {
            minRating = Double.parseDouble(minRatingParam);
        } catch (NumberFormatException e) {
            minRating = 0.0;
        }
    }
    
    // Apply filters if any
    if ((searchTerm != null && !searchTerm.trim().isEmpty()) || minRating > 0) {
        // We'll use JavaScript filtering for now
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Shelter List - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            .card-hover:hover {
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
                transition: all 0.3s ease;
            }

            .active-page {
                background-color: #2F5D50;
                color: white;
            }

            .star-rating {
                color: #C49A6C;
            }

            /* Custom scrollbar */
            ::-webkit-scrollbar {
                width: 8px;
            }

            ::-webkit-scrollbar-track {
                background: #f1f1f1;
                border-radius: 10px;
            }

            ::-webkit-scrollbar-thumb {
                background: #c1c1c1;
                border-radius: 10px;
            }

            ::-webkit-scrollbar-thumb:hover {
                background: #a8a8a8;
            }
            
            .line-clamp-2 {
                display: -webkit-box;
                -webkit-line-clamp: 2;
                -webkit-box-orient: vertical;
                overflow: hidden;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Main Dashboard Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Dashboard Title -->
                <div class="mb-8">
                    <h1 class="text-3xl font-bold text-[#2F5D50] border-b-2 border-[#E5E5E5] pb-4">Find Shelters</h1>
                    <p class="text-[#2B2B2B] mt-2">Browse and connect with animal shelters in your area</p>
                </div>

                <!-- Filter Section -->
                <div class="mb-8 p-6 bg-[#F9F9F9] rounded-lg border border-[#E5E5E5]">
                    <h2 class="text-xl font-semibold text-[#2F5D50] mb-4">Filter Shelters</h2>
                    <form id="filterForm" method="get" action="shelter_list.jsp" class="flex flex-wrap gap-6">
                        <!-- Search Filter -->
                        <div class="flex-1 min-w-[250px]">
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Search</label>
                            <input type="text" id="searchFilter" name="search" 
                                   value="<%= searchTerm != null ? escapeHtml(searchTerm) : "" %>"
                                   class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" 
                                   placeholder="Search by name or location...">
                        </div>

                        <!-- Rating Filter -->
                        <div class="flex-1 min-w-[250px]">
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Minimum Rating</label>
                            <select id="ratingFilter" name="minRating" 
                                    class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="0" <%= minRating == 0 ? "selected" : "" %>>Any Rating</option>
                                <option value="4" <%= minRating == 4 ? "selected" : "" %>>4 Stars & Above</option>
                                <option value="3" <%= minRating == 3 ? "selected" : "" %>>3 Stars & Above</option>
                                <option value="2" <%= minRating == 2 ? "selected" : "" %>>2 Stars & Above</option>
                                <option value="1" <%= minRating == 1 ? "selected" : "" %>>1 Star & Above</option>
                            </select>
                        </div>
                            
                        <!-- Filter Buttons -->
                        <div class="flex items-end gap-3">
                            <button type="submit" id="applyFilter" 
                                    class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                                <i class="fas fa-search mr-2"></i>Search
                            </button>
                            <button type="button" id="resetFilter" 
                                    class="px-6 py-3 bg-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#D5D5D5] transition duration-300">
                                <i class="fas fa-redo mr-2"></i>Reset
                            </button>
                        </div>
                    </form>
                </div>

                <!-- Results Count -->
                <div class="flex justify-between items-center mb-6">
                    <p class="text-[#2B2B2B]">
                        Showing <span id="resultCount" class="font-semibold"><%= shelters.size() %></span> shelters
                    </p>
                </div>

                <!-- Shelters Grid (4x2 layout) -->
                <div id="sheltersContainer" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <% 
                        int count = 0;
                        for (Shelter shelter : shelters) { 
                            double rating = shelter.getAvgRating();
                            int reviewCount = shelter.getReviewCount();
                            String description = shelter.getShelterDescription();
                            
                            // FALLBACK: If rating is 0, check directly from FeedbackDAO
                            if (rating == 0.0 && reviewCount == 0) {
                                FeedbackDAO feedbackDAO = new FeedbackDAO();
                                double directRating = feedbackDAO.getAverageRatingByShelterId(shelter.getShelterId());
                                int directCount = feedbackDAO.getFeedbackCountByShelterId(shelter.getShelterId());
                                
                                if (directRating > 0 || directCount > 0) {
                                    rating = directRating;
                                    reviewCount = directCount;
                                }
                            }
                    %>
                    <div class="shelter-card bg-white rounded-xl border border-[#E5E5E5] overflow-hidden card-hover">
                        <div class="relative">
                            <img src="<%= shelter.getPhotoPath() != null ? shelter.getPhotoPath() : "profile_picture/shelter/default.png" %>" 
                                 alt="<%= escapeHtml(shelter.getShelterName()) %>" 
                                 class="w-full h-48 object-cover">
                            <div class="absolute top-3 right-3 bg-[#6DBF89] text-[#06321F] px-3 py-1 rounded-full text-sm font-medium">
                                <i class="fas fa-check-circle mr-1"></i> Approved
                            </div>
                        </div>
                        <div class="p-5">
                            <h3 class="text-xl font-bold text-[#2B2B2B] mb-2"><%= escapeHtml(shelter.getShelterName()) %></h3>
                            <div class="flex items-center mb-3">
                                <i class="fas fa-map-marker-alt text-[#2F5D50] mr-2"></i>
                                <span class="text-[#2B2B2B]"><%= escapeHtml(shelter.getShelterAddress()) %></span>
                            </div>
                            <div class="flex items-center mb-4">
                                <div class="star-rating mr-2">
                                    <%= generateStars(rating) %>
                                </div>
                                <span class="text-[#2B2B2B] font-medium"><%= String.format("%.1f", rating) %></span>
                                <span class="text-[#888] ml-1">(<%= reviewCount %> reviews)</span>
                            </div>
                            <div class="mb-4">
                                <span class="inline-block bg-[#A8E6CF] text-[#2B2B2B] px-3 py-1 rounded-full text-sm mr-2 mb-2">
                                    <i class="fas fa-paw mr-1"></i> Shelter
                                </span>
                            </div>
                            <p class="text-[#666] text-sm mb-4 line-clamp-2">
                                <%= description != null && !description.isEmpty() ? escapeHtml(description.length() > 150 ? description.substring(0, 150) + "..." : description) : "Animal shelter providing care and adoption services." %>
                            </p>
                            <a href="shelter_info.jsp?id=<%= shelter.getShelterId() %>" 
                                class="px-4 py-2 bg-[#2F5D50] text-white rounded-lg hover:bg-[#24483E] transition duration-300">
                                 View Details
                             </a>
                        </div>
                    </div>
                    <% 
                        count++;
                    } %>
                    
                    <% if (shelters.isEmpty()) { %>
                    <div class="col-span-4 text-center py-8">
                        <i class="fas fa-home text-4xl text-[#E5E5E5] mb-4"></i>
                        <p class="text-[#888]">No shelters available at the moment.</p>
                    </div>
                    <% } %>
                </div>

                <!-- Simple Pagination Note -->
                <% if (shelters.size() > 0) { %>
                <div class="text-center text-[#888] mt-4">
                    <p>Showing <%= shelters.size() %> shelters</p>
                </div>
                <% } %>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
            // DOM Elements
            const resetFilterBtn = document.getElementById('resetFilter');
            const filterForm = document.getElementById('filterForm');

            // Initialize
            document.addEventListener('DOMContentLoaded', function () {
                attachEventListeners();
                
                // Apply JavaScript filtering if needed
                applyClientSideFiltering();
            });

            // Apply client-side filtering (for better UX)
            function applyClientSideFiltering() {
                const searchTerm = '<%= searchTerm != null ? escapeJavaScript(searchTerm) : "" %>';
                const minRating = <%= minRating %>;
                
                if (searchTerm || minRating > 0) {
                    const shelterCards = document.querySelectorAll('.shelter-card');
                    let visibleCount = 0;
                    
                    shelterCards.forEach(card => {
                        const shelterName = card.querySelector('h3').textContent.toLowerCase();
                        const shelterAddress = card.querySelector('.fa-map-marker-alt').nextElementSibling.textContent.toLowerCase();
                        const ratingElement = card.querySelector('.star-rating').nextElementSibling;
                        const ratingText = ratingElement.textContent.trim();
                        const shelterRating = parseFloat(ratingText);
                        
                        let shouldShow = true;
                        
                        // Apply search filter
                        if (searchTerm && searchTerm.trim() !== '') {
                            const searchLower = searchTerm.toLowerCase();
                            if (!shelterName.includes(searchLower) && !shelterAddress.includes(searchLower)) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply rating filter
                        if (minRating > 0 && shelterRating < minRating) {
                            shouldShow = false;
                        }
                        
                        if (shouldShow) {
                            card.style.display = 'block';
                            visibleCount++;
                        } else {
                            card.style.display = 'none';
                        }
                    });
                    
                    // Update result count
                    const resultCount = document.getElementById('resultCount');
                    if (resultCount) {
                        resultCount.textContent = visibleCount;
                    }
                    
                    // Show message if no results
                    if (visibleCount === 0) {
                        const container = document.getElementById('sheltersContainer');
                        container.innerHTML = `
                            <div class="col-span-4 text-center py-8">
                                <i class="fas fa-search text-4xl text-[#E5E5E5] mb-4"></i>
                                <p class="text-[#888]">No shelters match your filter criteria.</p>
                                <p class="text-[#888] text-sm mt-2">Try different search terms or rating filters.</p>
                            </div>
                        `;
                    }
                }
            }

            // Reset filters
            function resetFilters() {
                // Clear form inputs
                document.getElementById('searchFilter').value = '';
                document.getElementById('ratingFilter').value = '0';
                
                // Submit the form to reload page without filters
                filterForm.submit();
            }

            // Attach event listeners
            function attachEventListeners() {
                resetFilterBtn.addEventListener('click', resetFilters);

                // Add Enter key support for search
                const searchFilter = document.getElementById('searchFilter');
                searchFilter.addEventListener('keyup', (e) => {
                    if (e.key === 'Enter') {
                        filterForm.submit();
                    }
                });
            }
        </script>

    </body>
</html>

<%!
    // Helper method to generate star HTML
    private String generateStars(double rating) {
        StringBuilder stars = new StringBuilder();
        int fullStars = (int) Math.floor(rating);
        boolean hasHalfStar = rating % 1 >= 0.5;
        
        for (int i = 1; i <= 5; i++) {
            if (i <= fullStars) {
                stars.append("<i class='fas fa-star'></i>");
            } else if (i == fullStars + 1 && hasHalfStar) {
                stars.append("<i class='fas fa-star-half-alt'></i>");
            } else {
                stars.append("<i class='far fa-star'></i>");
            }
        }
        
        return stars.toString();
    }
    
    // Helper method to escape HTML for safety
    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
    
    // Helper method to escape JavaScript strings
    private String escapeJavaScript(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("'", "\\'")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }
%>