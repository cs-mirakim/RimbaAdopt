<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.ShelterDAO" %>
<%@ page import="com.rimba.adopt.dao.FeedbackDAO" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>

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
    List shelters = shelterDAO.getSheltersForPublic();
    FeedbackDAO feedbackDAO = new FeedbackDAO();

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

    // Count shelters by rating for display (NO BACKEND FILTERING)
    int countAny = shelters.size();
    Map ratingCounts = new HashMap();
    ratingCounts.put("5plus", Integer.valueOf(0));  // 5.0+
    ratingCounts.put("4plus", Integer.valueOf(0));  // 4.0-4.9
    ratingCounts.put("3plus", Integer.valueOf(0));  // 3.0-3.9
    ratingCounts.put("2plus", Integer.valueOf(0));  // 2.0-2.9
    ratingCounts.put("1plus", Integer.valueOf(0));  // 1.0-1.9
    ratingCounts.put("0plus", Integer.valueOf(0));  // 0.0-0.9 or no reviews

    for (Iterator it = shelters.iterator(); it.hasNext();) {
        Shelter shelter = (Shelter) it.next();
        double rating = feedbackDAO.getAverageRatingByShelterId(shelter.getShelterId());
        int reviewCount = feedbackDAO.getFeedbackCountByShelterId(shelter.getShelterId());

        // Update shelter object dengan data terkini
        shelter.setAvgRating(rating);
        shelter.setReviewCount(reviewCount);

        // Count by rating range
        if (reviewCount == 0) {
            Integer current = (Integer) ratingCounts.get("0plus");
            ratingCounts.put("0plus", Integer.valueOf(current.intValue() + 1));
        } else if (rating >= 5.0) {
            Integer current = (Integer) ratingCounts.get("5plus");
            ratingCounts.put("5plus", Integer.valueOf(current.intValue() + 1));
        } else if (rating >= 4.0) {
            Integer current = (Integer) ratingCounts.get("4plus");
            ratingCounts.put("4plus", Integer.valueOf(current.intValue() + 1));
        } else if (rating >= 3.0) {
            Integer current = (Integer) ratingCounts.get("3plus");
            ratingCounts.put("3plus", Integer.valueOf(current.intValue() + 1));
        } else if (rating >= 2.0) {
            Integer current = (Integer) ratingCounts.get("2plus");
            ratingCounts.put("2plus", Integer.valueOf(current.intValue() + 1));
        } else if (rating >= 1.0) {
            Integer current = (Integer) ratingCounts.get("1plus");
            ratingCounts.put("1plus", Integer.valueOf(current.intValue() + 1));
        } else {
            Integer current = (Integer) ratingCounts.get("0plus");
            ratingCounts.put("0plus", Integer.valueOf(current.intValue() + 1));
        }
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

            /* Filter button styles */
            .filter-rating-btn {
                padding: 8px 16px;
                border-radius: 9999px;
                font-weight: 500;
                transition: all 0.2s;
                cursor: pointer;
                border: 1px solid #E5E5E5;
            }

            .filter-rating-btn:hover {
                background-color: #F6F3E7;
            }

            .filter-rating-btn.active {
                background-color: #2F5D50;
                color: white;
                border-color: #2F5D50;
            }

            .filter-rating-btn.active:hover {
                background-color: #24483E;
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

                    <!-- Search Filter -->
                    <div class="mb-6">
                        <label class="block text-[#2B2B2B] mb-2 font-medium">Search</label>
                        <div class="flex gap-3">
                            <input type="text" id="searchFilter" 
                                   class="flex-1 p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" 
                                   placeholder="Search by name or location...">
                            <button id="searchBtn" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                                <i class="fas fa-search mr-2"></i>Search
                            </button>
                        </div>
                    </div>

                    <!-- Rating Filter Buttons -->
                    <div>
                        <label class="block text-[#2B2B2B] mb-2 font-medium">Filter by Rating</label>
                        <div class="flex flex-wrap gap-2">
                            <button class="filter-rating-btn active" data-rating="all">
                                All Shelters (<%= countAny%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="5plus">
                                ⭐⭐⭐⭐⭐ 5 Stars (<%= ((Integer) ratingCounts.get("5plus")).intValue()%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="4plus">
                                ⭐⭐⭐⭐ 4+ Stars (<%= ((Integer) ratingCounts.get("4plus")).intValue()%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="3plus">
                                ⭐⭐⭐ 3+ Stars (<%= ((Integer) ratingCounts.get("3plus")).intValue()%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="2plus">
                                ⭐⭐ 2+ Stars (<%= ((Integer) ratingCounts.get("2plus")).intValue()%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="1plus">
                                ⭐ 1+ Star (<%= ((Integer) ratingCounts.get("1plus")).intValue()%>)
                            </button>
                            <button class="filter-rating-btn" data-rating="0plus">
                                No Reviews Yet (<%= ((Integer) ratingCounts.get("0plus")).intValue()%>)
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Results Count -->
                <div class="flex justify-between items-center mb-6">
                    <p class="text-[#2B2B2B]">
                        Showing <span id="resultCount" class="font-semibold"><%= shelters.size()%></span> shelters
                    </p>
                    <button id="resetFilter" class="px-4 py-2 text-sm text-[#2F5D50] hover:text-[#24483E] font-medium">
                        <i class="fas fa-redo mr-1"></i>Reset Filters
                    </button>
                </div>

                <!-- Shelters Grid (4x2 layout) -->
                <div id="sheltersContainer" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <%
                        for (Iterator it = shelters.iterator(); it.hasNext();) {
                            Shelter shelter = (Shelter) it.next();
                            double rating = shelter.getAvgRating();
                            int reviewCount = shelter.getReviewCount();

                            // Get actual rating dari FeedbackDAO
                            if (rating == 0.0 && reviewCount == 0) {
                                rating = feedbackDAO.getAverageRatingByShelterId(shelter.getShelterId());
                                reviewCount = feedbackDAO.getFeedbackCountByShelterId(shelter.getShelterId());

                                if (rating > 0 || reviewCount > 0) {
                                    shelter.setAvgRating(rating);
                                    shelter.setReviewCount(reviewCount);
                                }
                            }

                            // Determine rating category for data attribute
                            String ratingCategory = "0plus";
                            if (reviewCount == 0) {
                                ratingCategory = "0plus";
                            } else if (rating >= 5.0) {
                                ratingCategory = "5plus";
                            } else if (rating >= 4.0) {
                                ratingCategory = "4plus";
                            } else if (rating >= 3.0) {
                                ratingCategory = "3plus";
                            } else if (rating >= 2.0) {
                                ratingCategory = "2plus";
                            } else if (rating >= 1.0) {
                                ratingCategory = "1plus";
                            }

                            String description = shelter.getShelterDescription();
                    %>
                    <div class="shelter-card bg-white rounded-xl border border-[#E5E5E5] overflow-hidden card-hover"
                         data-name="<%= escapeHtml(shelter.getShelterName()).toLowerCase()%>"
                         data-address="<%= escapeHtml(shelter.getShelterAddress()).toLowerCase()%>"
                         data-rating="<%= rating%>"
                         data-review-count="<%= reviewCount%>"
                         data-rating-category="<%= ratingCategory%>">
                        <div class="relative">
                            <img src="<%= shelter.getPhotoPath() != null ? shelter.getPhotoPath() : "profile_picture/shelter/default.png"%>" 
                                 alt="<%= escapeHtml(shelter.getShelterName())%>" 
                                 class="w-full h-48 object-cover"
                                 onerror="this.src='https://via.placeholder.com/400x300?text=Shelter'">
                            <div class="absolute top-3 right-3 bg-[#6DBF89] text-[#06321F] px-3 py-1 rounded-full text-sm font-medium">
                                <i class="fas fa-check-circle mr-1"></i> Approved
                            </div>
                        </div>
                        <div class="p-5">
                            <h3 class="text-xl font-bold text-[#2B2B2B] mb-2"><%= escapeHtml(shelter.getShelterName())%></h3>
                            <div class="flex items-center mb-3">
                                <i class="fas fa-map-marker-alt text-[#2F5D50] mr-2"></i>
                                <span class="text-[#2B2B2B]"><%= escapeHtml(shelter.getShelterAddress())%></span>
                            </div>
                            <div class="flex items-center mb-4">
                                <div class="star-rating mr-2">
                                    <%= generateStars(rating)%>
                                </div>
                                <% if (reviewCount > 0) {%>
                                <span class="text-[#2B2B2B] font-medium"><%= String.format("%.1f", rating)%></span>
                                <span class="text-[#888] ml-1">(<%= reviewCount%> <%= reviewCount == 1 ? "review" : "reviews"%>)</span>
                                <% } else { %>
                                <span class="text-[#888] font-medium">No reviews yet</span>
                                <% }%>
                            </div>
                            <div class="mb-4">
                                <span class="inline-block bg-[#A8E6CF] text-[#2B2B2B] px-3 py-1 rounded-full text-sm mr-2 mb-2">
                                    <i class="fas fa-paw mr-1"></i> Shelter
                                </span>
                            </div>
                            <p class="text-[#666] text-sm mb-4 line-clamp-2">
                                <%= description != null && !description.isEmpty() ? escapeHtml(description.length() > 150 ? description.substring(0, 150) + "..." : description) : "Animal shelter providing care and adoption services."%>
                            </p>
                            <a href="shelter_info.jsp?id=<%= shelter.getShelterId()%>" 
                               class="block w-full text-center px-4 py-2 bg-[#2F5D50] text-white rounded-lg hover:bg-[#24483E] transition duration-300">
                                View Details
                            </a>
                        </div>
                    </div>
                    <% } %>

                    <% if (shelters.isEmpty()) { %>
                    <div class="col-span-4 text-center py-8">
                        <i class="fas fa-home text-4xl text-[#E5E5E5] mb-4"></i>
                        <p class="text-[#888]">No shelters available at the moment.</p>
                    </div>
                    <% } %>
                </div>

                <!-- Simple Pagination Note -->
                <% if (shelters.size() > 0) {%>
                <div class="text-center text-[#888] mt-4">
                    <p>Found <span id="filteredCount"><%= shelters.size()%></span> shelters matching your criteria</p>
                </div>
                <% }%>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
            // =======================================================
            // CONFIGURATION AND STATE MANAGEMENT
            // =======================================================
            var currentRatingFilter = 'all';
            var currentSearchTerm = '';
            var allSheltersCount = <%= shelters.size()%>;
            var pageLoaded = false;
            var DEBUG = false;

            // =======================================================
            // 1. IMAGE LOADING HANDLER (UNTUK STOP LOADING ICON)
            // =======================================================
            function handleAllImagesLoaded() {
                return new Promise(function (resolve) {
                    var images = document.querySelectorAll('.shelter-card img');
                    var totalImages = images.length;
                    var loadedCount = 0;

                    if (DEBUG)
                        console.log('Checking ' + totalImages + ' shelter images...');

                    if (totalImages === 0) {
                        resolve();
                        return;
                    }

                    function checkCompletion() {
                        loadedCount++;
                        if (DEBUG && loadedCount % 5 === 0) {
                            console.log('Images loaded: ' + loadedCount + '/' + totalImages);
                        }

                        if (loadedCount >= totalImages) {
                            if (DEBUG)
                                console.log('All shelter images loaded');
                            resolve();
                        }
                    }

                    for (var i = 0; i < images.length; i++) {
                        var img = images[i];

                        if (img.complete && img.naturalHeight !== 0) {
                            checkCompletion();
                        } else {
                            img.addEventListener('load', checkCompletion);
                            img.addEventListener('error', checkCompletion);
                        }
                    }

                    // Check if all already loaded
                    if (loadedCount === totalImages) {
                        resolve();
                        return;
                    }

                    // Fallback timeout (3 seconds)
                    setTimeout(function () {
                        if (DEBUG)
                            console.warn('Image loading timeout. Loaded: ' + loadedCount + '/' + totalImages);
                        resolve();
                    }, 3000);
                });
            }

            // =======================================================
            // 2. FORCE STOP LOADING INDICATOR (PENTING!)
            // =======================================================
            function forceStopLoadingIndicator() {
                try {
                    if (pageLoaded)
                        return;

                    pageLoaded = true;
                    if (DEBUG)
                        console.log('Force stopping loading indicator...');

                    // Method 1: window.stop() - stops all pending requests
                    if (window.stop && typeof window.stop === 'function') {
                        window.stop();
                    }

                    // Method 2: Mark page as fully loaded
                    document.documentElement.setAttribute('data-page-loaded', 'true');
                    document.body.classList.add('page-loaded-complete');

                    // Method 3: Hide any loading animations
                    var loadingAnimations = document.querySelectorAll('.fa-spinner, [class*="loading"]');
                    for (var i = 0; i < loadingAnimations.length; i++) {
                        loadingAnimations[i].style.display = 'none';
                    }

                    if (DEBUG)
                        console.log('Loading indicator stopped');
                } catch (e) {
                    if (DEBUG)
                        console.warn('Error stopping loading indicator:', e);
                }
            }

            // =======================================================
            // 3. FILTER FUNCTIONS (SAMA TAPI DITAMBAH ERROR HANDLING)
            // =======================================================

            // Attach event listeners
            function attachEventListeners() {
                try {
                    // Search button
                    var searchBtn = document.getElementById('searchBtn');
                    if (searchBtn) {
                        searchBtn.addEventListener('click', function () {
                            currentSearchTerm = document.getElementById('searchFilter').value.trim().toLowerCase();
                            filterShelters();
                        });
                    }

                    // Search input - Enter key
                    var searchFilter = document.getElementById('searchFilter');
                    if (searchFilter) {
                        searchFilter.addEventListener('keyup', function (e) {
                            if (e.key === 'Enter') {
                                currentSearchTerm = this.value.trim().toLowerCase();
                                filterShelters();
                            }
                        });

                        // Search input - real-time filtering (optional)
                        searchFilter.addEventListener('input', function () {
                            currentSearchTerm = this.value.trim().toLowerCase();
                            filterShelters();
                        });
                    }

                    // Rating filter buttons
                    var filterButtons = document.querySelectorAll('.filter-rating-btn');
                    for (var i = 0; i < filterButtons.length; i++) {
                        filterButtons[i].addEventListener('click', function () {
                            // Update active button
                            var allButtons = document.querySelectorAll('.filter-rating-btn');
                            for (var j = 0; j < allButtons.length; j++) {
                                allButtons[j].classList.remove('active');
                            }
                            this.classList.add('active');

                            // Set current filter
                            currentRatingFilter = this.getAttribute('data-rating');

                            // Apply filter
                            filterShelters();
                        });
                    }

                    // Reset filter button
                    var resetBtn = document.getElementById('resetFilter');
                    if (resetBtn) {
                        resetBtn.addEventListener('click', function () {
                            resetFilters();
                        });
                    }
                } catch (e) {
                    console.error('Error attaching event listeners:', e);
                }
            }

            // Apply initial filters from URL parameters (optional)
            function applyInitialFiltersFromURL() {
                try {
                    var urlParams = new URLSearchParams(window.location.search);
                    var searchParam = urlParams.get('search');
                    var ratingParam = urlParams.get('minRating');

                    if (searchParam) {
                        document.getElementById('searchFilter').value = searchParam;
                        currentSearchTerm = searchParam.toLowerCase();
                    }

                    if (ratingParam) {
                        // Convert backend rating param to frontend category
                        var rating = parseFloat(ratingParam);
                        var ratingCategory = 'all';

                        if (rating === -1) {
                            ratingCategory = '0plus';
                        } else if (rating >= 5.0) {
                            ratingCategory = '5plus';
                        } else if (rating >= 4.0) {
                            ratingCategory = '4plus';
                        } else if (rating >= 3.0) {
                            ratingCategory = '3plus';
                        } else if (rating >= 2.0) {
                            ratingCategory = '2plus';
                        } else if (rating >= 1.0) {
                            ratingCategory = '1plus';
                        }

                        // Activate corresponding button
                        var buttons = document.querySelectorAll('.filter-rating-btn');
                        for (var i = 0; i < buttons.length; i++) {
                            var btn = buttons[i];
                            btn.classList.remove('active');
                            if (btn.getAttribute('data-rating') === ratingCategory) {
                                btn.classList.add('active');
                                currentRatingFilter = ratingCategory;
                            }
                        }
                    }
                } catch (e) {
                    console.error('Error applying initial filters:', e);
                }
            }

            // Main filtering function
            function filterShelters() {
                try {
                    var shelterCards = document.querySelectorAll('.shelter-card');
                    var visibleCount = 0;

                    for (var i = 0; i < shelterCards.length; i++) {
                        var card = shelterCards[i];
                        var shouldShow = true;

                        // Get card data
                        var shelterName = card.getAttribute('data-name');
                        var shelterAddress = card.getAttribute('data-address');
                        var shelterRating = parseFloat(card.getAttribute('data-rating'));
                        var reviewCount = parseInt(card.getAttribute('data-review-count'));
                        var ratingCategory = card.getAttribute('data-rating-category');

                        // Apply search filter
                        if (currentSearchTerm && currentSearchTerm.trim() !== '') {
                            if (shelterName.indexOf(currentSearchTerm) === -1 &&
                                    shelterAddress.indexOf(currentSearchTerm) === -1) {
                                shouldShow = false;
                            }
                        }

                        // Apply rating filter
                        if (currentRatingFilter !== 'all') {
                            if (currentRatingFilter === '0plus') {
                                // No reviews filter
                                if (reviewCount > 0) {
                                    shouldShow = false;
                                }
                            } else {
                                // Rating range filter
                                if (ratingCategory !== currentRatingFilter) {
                                    shouldShow = false;
                                }
                            }
                        }

                        // Show/hide card
                        if (shouldShow) {
                            card.style.display = 'block';
                            visibleCount++;
                        } else {
                            card.style.display = 'none';
                        }
                    }

                    // Update counts
                    var resultCount = document.getElementById('resultCount');
                    var filteredCount = document.getElementById('filteredCount');

                    if (resultCount)
                        resultCount.textContent = visibleCount;
                    if (filteredCount)
                        filteredCount.textContent = visibleCount;

                    // Show no results message
                    var container = document.getElementById('sheltersContainer');
                    if (!container)
                        return;

                    var noResultsMsg = container.querySelector('.no-results-message');

                    if (visibleCount === 0 && allSheltersCount > 0) {
                        if (!noResultsMsg) {
                            var messageDiv = document.createElement('div');
                            messageDiv.className = 'no-results-message col-span-4 text-center py-8';
                            messageDiv.innerHTML = '\
                        <i class="fas fa-search text-4xl text-[#E5E5E5] mb-4"></i>\
                        <p class="text-[#888] text-lg mb-2">No shelters found matching your criteria</p>\
                        <p class="text-[#888] text-sm mb-4">Try different search terms or rating filters</p>\
                        <button onclick="resetFilters()" class="px-4 py-2 bg-[#2F5D50] text-white rounded-lg hover:bg-[#24483E] transition duration-300">\
                            Reset All Filters\
                        </button>\
                    ';
                            container.appendChild(messageDiv);
                        }
                    } else if (noResultsMsg) {
                        container.removeChild(noResultsMsg);
                    }

                    // Update URL without reloading (optional)
                    updateURLWithoutReload();

                    if (DEBUG)
                        console.log('Filter applied. Showing ' + visibleCount + ' of ' + allSheltersCount + ' shelters');
                } catch (e) {
                    console.error('Error filtering shelters:', e);
                }
            }

            // Update URL with current filters (optional - for sharing)
            function updateURLWithoutReload() {
                try {
                    var url = new URL(window.location);

                    if (currentSearchTerm) {
                        url.searchParams.set('search', currentSearchTerm);
                    } else {
                        url.searchParams.delete('search');
                    }

                    // Convert frontend rating category to backend minRating
                    var minRatingParam = '0';
                    if (currentRatingFilter === '0plus') {
                        minRatingParam = '-1';
                    } else if (currentRatingFilter === '5plus') {
                        minRatingParam = '5';
                    } else if (currentRatingFilter === '4plus') {
                        minRatingParam = '4';
                    } else if (currentRatingFilter === '3plus') {
                        minRatingParam = '3';
                    } else if (currentRatingFilter === '2plus') {
                        minRatingParam = '2';
                    } else if (currentRatingFilter === '1plus') {
                        minRatingParam = '1';
                    }

                    if (currentRatingFilter !== 'all') {
                        url.searchParams.set('minRating', minRatingParam);
                    } else {
                        url.searchParams.delete('minRating');
                    }

                    // Update URL tanpa reload page
                    window.history.replaceState({}, '', url);
                } catch (e) {
                    console.error('Error updating URL:', e);
                }
            }

            // Reset all filters
            function resetFilters() {
                try {
                    // Reset search
                    var searchFilter = document.getElementById('searchFilter');
                    if (searchFilter)
                        searchFilter.value = '';
                    currentSearchTerm = '';

                    // Reset rating filter
                    var buttons = document.querySelectorAll('.filter-rating-btn');
                    for (var i = 0; i < buttons.length; i++) {
                        var btn = buttons[i];
                        btn.classList.remove('active');
                        if (btn.getAttribute('data-rating') === 'all') {
                            btn.classList.add('active');
                        }
                    }
                    currentRatingFilter = 'all';

                    // Apply filter (show all)
                    filterShelters();

                    // Clear URL parameters
                    var url = new URL(window.location);
                    url.search = '';
                    window.history.replaceState({}, '', url);
                } catch (e) {
                    console.error('Error resetting filters:', e);
                }
            }

            // =======================================================
            // 4. INITIALIZATION WITH LOADING HANDLING
            // =======================================================
            document.addEventListener('DOMContentLoaded', function () {
                if (DEBUG)
                    console.log('Shelter List page - DOM loaded. Total shelters:', allSheltersCount);

                try {
                    // Attach event listeners
                    attachEventListeners();

                    // Apply initial filter jika ada URL parameters
                    applyInitialFiltersFromURL();

                    // Apply initial filtering
                    filterShelters();

                    // Handle image loading
                    handleAllImagesLoaded().then(function () {
                        if (DEBUG)
                            console.log('All images processed successfully');
                    }).catch(function (error) {
                        console.warn('Image loading issue:', error);
                    });
                } catch (e) {
                    console.error('Error during initialization:', e);
                }
            });

            // =======================================================
            // 5. WINDOW LOAD EVENT - UTAMA UNTUK STOP LOADING ICON
            // =======================================================
            window.addEventListener('load', function () {
                if (DEBUG)
                    console.log('Shelter List page - Window fully loaded');

                // Force stop loading indicator after 500ms
                setTimeout(function () {
                    forceStopLoadingIndicator();
                }, 500);
            });

            // =======================================================
            // 6. FALLBACK TIMEOUT - JIKA WINDOW.LOAD TAK TRIGGER
            // =======================================================
            setTimeout(function () {
                if (!pageLoaded) {
                    if (DEBUG)
                        console.warn('Fallback: Forcing page load completion after 6 seconds');
                    forceStopLoadingIndicator();
                }
            }, 6000);

            // =======================================================
            // 7. ERROR HANDLING (PREVENT LOADING HANG)
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
        if (input == null) {
            return "";
        }
        return input.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>