<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
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

// Get filter parameters
String speciesFilter = request.getParameter("species");
String breedFilter = request.getParameter("breed");
String ageFilter = request.getParameter("age");
String sizeFilter = request.getParameter("size");
String genderFilter = request.getParameter("gender");
String locationFilter = request.getParameter("location");
String searchTerm = request.getParameter("search");

// Get all available pets from database
PetsDAO petsDAO = new PetsDAO();
List<Pets> pets = petsDAO.getAllAvailablePets();

// Apply filters if any
if ((speciesFilter != null && !speciesFilter.trim().isEmpty()) ||
    (breedFilter != null && !breedFilter.trim().isEmpty()) ||
    (ageFilter != null && !ageFilter.trim().isEmpty()) ||
    (sizeFilter != null && !sizeFilter.trim().isEmpty()) ||
    (genderFilter != null && !genderFilter.trim().isEmpty()) ||
    (locationFilter != null && !locationFilter.trim().isEmpty()) ||
    (searchTerm != null && !searchTerm.trim().isEmpty())) {
    // We'll use JavaScript filtering for better UX
}
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Pet List - Rimba Adopt</title>
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

            /* Gender badges */
            .gender-male {
                background-color: #2F5D50;
                color: white;
            }

            .gender-female {
                background-color: #C49A6C;
                color: white;
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
                    <h1 class="text-3xl font-bold text-[#2F5D50] border-b-2 border-[#E5E5E5] pb-4">Find Your Perfect Pet</h1>
                    <p class="text-[#2B2B2B] mt-2">Browse adorable pets waiting for their forever homes</p>
                </div>

                <!-- Filter Section -->
                <div class="mb-8 p-6 bg-[#F9F9F9] rounded-lg border border-[#E5E5E5]">
                    <h2 class="text-xl font-semibold text-[#2F5D50] mb-4">Filter Pets</h2>
                    <form id="filterForm" method="get" action="pet_list.jsp" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <!-- Species Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Species</label>
                            <select id="speciesFilter" name="species" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Species</option>
                                <option value="dog" <%= "dog".equals(speciesFilter) ? "selected" : "" %>>Dog</option>
                                <option value="cat" <%= "cat".equals(speciesFilter) ? "selected" : "" %>>Cat</option>
                                <option value="rabbit" <%= "rabbit".equals(speciesFilter) ? "selected" : "" %>>Rabbit</option>
                                <option value="bird" <%= "bird".equals(speciesFilter) ? "selected" : "" %>>Bird</option>
                                <option value="other" <%= "other".equals(speciesFilter) ? "selected" : "" %>>Other</option>
                            </select>
                        </div>

                        <!-- Breed Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Breed</label>
                            <select id="breedFilter" name="breed" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Breeds</option>
                                <!-- Breed options will be populated dynamically -->
                            </select>
                        </div>

                        <!-- Age Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Age</label>
                            <select id="ageFilter" name="age" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Ages</option>
                                <option value="baby" <%= "baby".equals(ageFilter) ? "selected" : "" %>>Baby (0-1 years)</option>
                                <option value="young" <%= "young".equals(ageFilter) ? "selected" : "" %>>Young (1-3 years)</option>
                                <option value="adult" <%= "adult".equals(ageFilter) ? "selected" : "" %>>Adult (3-8 years)</option>
                                <option value="senior" <%= "senior".equals(ageFilter) ? "selected" : "" %>>Senior (8+ years)</option>
                            </select>
                        </div>

                        <!-- Size Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Size</label>
                            <select id="sizeFilter" name="size" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Sizes</option>
                                <option value="small" <%= "small".equals(sizeFilter) ? "selected" : "" %>>Small</option>
                                <option value="medium" <%= "medium".equals(sizeFilter) ? "selected" : "" %>>Medium</option>
                                <option value="large" <%= "large".equals(sizeFilter) ? "selected" : "" %>>Large</option>
                            </select>
                        </div>

                        <!-- Gender Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Gender</label>
                            <select id="genderFilter" name="gender" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Genders</option>
                                <option value="male" <%= "male".equals(genderFilter) ? "selected" : "" %>>Male</option>
                                <option value="female" <%= "female".equals(genderFilter) ? "selected" : "" %>>Female</option>
                            </select>
                        </div>

                        <!-- Search Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Search</label>
                            <input type="text" id="searchFilter" name="search" 
                                   value="<%= searchTerm != null ? escapeHtml(searchTerm) : "" %>"
                                   class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" 
                                   placeholder="Search by pet name...">
                        </div>
                    </form>

                    <!-- Filter Buttons -->
                    <div class="flex justify-end gap-3 mt-6">
                        <button type="submit" form="filterForm" id="applyFilter" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                            <i class="fas fa-filter mr-2"></i>Apply Filters
                        </button>
                        <button type="button" id="resetFilter" class="px-6 py-3 bg-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#D5D5D5] transition duration-300">
                            <i class="fas fa-redo mr-2"></i>Reset
                        </button>
                    </div>
                </div>

                <!-- Results Count -->
                <div class="flex justify-between items-center mb-6">
                    <p class="text-[#2B2B2B]">
                        Showing <span id="resultCount" class="font-semibold"><%= pets.size() %></span> pets
                    </p>
                    <div class="text-[#2B2B2B]">
                        Page <span id="currentPage" class="font-semibold">1</span> of <span id="totalPages" class="font-semibold">1</span>
                    </div>
                </div>

                <!-- Pets Grid (4x2 layout) -->
                <div id="petsContainer" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <% 
                    int count = 0;
                    for (Pets pet : pets) { 
                        String ageCategory = getAgeCategory(pet.getAge());
                    %>
                    <div class="pet-card bg-white rounded-xl border border-[#E5E5E5] overflow-hidden card-hover">
                        <div class="relative">
                            <img src="<%= pet.getPhotoPath() != null ? pet.getPhotoPath() : "animal_picture/default.png" %>" 
                                 alt="<%= escapeHtml(pet.getName()) %>" 
                                 class="w-full h-48 object-cover">
                            <div class="absolute top-3 right-3">
                                <span class="px-3 py-1 rounded-full text-sm font-medium <%= "male".equals(pet.getGender()) ? "gender-male" : "gender-female" %>">
                                    <i class="fas <%= "male".equals(pet.getGender()) ? "fa-mars" : "fa-venus" %> mr-1"></i> 
                                    <%= "male".equals(pet.getGender()) ? "Male" : "Female" %>
                                </span>
                            </div>
                            <div class="absolute top-3 left-3 bg-[#6DBF89] text-[#06321F] px-3 py-1 rounded-full text-sm font-medium">
                                Available
                            </div>
                        </div>
                        <div class="p-5">
                            <h3 class="text-xl font-bold text-[#2B2B2B] mb-2"><%= escapeHtml(pet.getName()) %></h3>
                            <div class="flex items-center mb-3">
                                <div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">
                                    <i class="fas <%= getSpeciesIcon(pet.getSpecies()) %> text-[#2F5D50]"></i>
                                </div>
                                <div>
                                    <p class="text-[#2B2B2B] font-medium"><%= capitalizeFirstLetter(pet.getSpecies()) %></p>
                                    <p class="text-[#666] text-sm"><%= pet.getBreed() != null ? escapeHtml(pet.getBreed()) : "Mixed Breed" %></p>
                                </div>
                            </div>
                            <div class="grid grid-cols-2 gap-3 mb-4">
                                <div>
                                    <p class="text-xs text-[#888]">Age</p>
                                    <p class="font-medium"><%= pet.getAge() != null ? pet.getAge() + " years" : "Unknown" %></p>
                                </div>
                                <div>
                                    <p class="text-xs text-[#888]">Size</p>
                                    <p class="font-medium"><%= pet.getSize() != null ? capitalizeFirstLetter(pet.getSize()) : "Not specified" %></p>
                                </div>
                                <div>
                                    <p class="text-xs text-[#888]">Color</p>
                                    <p class="font-medium"><%= pet.getColor() != null ? escapeHtml(pet.getColor()) : "Not specified" %></p>
                                </div>
                                <div>
                                    <p class="text-xs text-[#888]">Shelter</p>
                                    <p class="font-medium"><%= pet.getShelterId() %></p>
                                </div>
                            </div>
                            <p class="text-[#666] text-sm mb-4 line-clamp-2">
                                <%= pet.getDescription() != null && !pet.getDescription().isEmpty() ? 
                                    escapeHtml(pet.getDescription().length() > 100 ? 
                                    pet.getDescription().substring(0, 100) + "..." : pet.getDescription()) : 
                                    "A lovely pet looking for a forever home." %>
                            </p>
                            <a href="pet_info.jsp?id=<%= pet.getPetId() %>" 
                               class="block w-full text-center py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                                View Details
                            </a>
                        </div>
                    </div>
                    <% 
                        count++;
                    } %>
                    
                    <% if (pets.isEmpty()) { %>
                    <div class="col-span-1 md:col-span-2 lg:grid-cols-4 text-center py-12">
                        <i class="fas fa-paw text-5xl text-[#E5E5E5] mb-4"></i>
                        <h3 class="text-xl font-semibold text-[#2B2B2B] mb-2">No pets available at the moment</h3>
                        <p class="text-[#666]">Check back later for new arrivals.</p>
                    </div>
                    <% } %>
                </div>

                <!-- Simple Pagination Note -->
                <% if (pets.size() > 0) { %>
                <div class="text-center text-[#888] mt-4">
                    <p>Showing <%= pets.size() %> pets available for adoption</p>
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
                const speciesFilter = '<%= speciesFilter != null ? escapeJavaScript(speciesFilter) : "" %>';
                const breedFilter = '<%= breedFilter != null ? escapeJavaScript(breedFilter) : "" %>';
                const ageFilter = '<%= ageFilter != null ? escapeJavaScript(ageFilter) : "" %>';
                const sizeFilter = '<%= sizeFilter != null ? escapeJavaScript(sizeFilter) : "" %>';
                const genderFilter = '<%= genderFilter != null ? escapeJavaScript(genderFilter) : "" %>';
                const searchTerm = '<%= searchTerm != null ? escapeJavaScript(searchTerm) : "" %>';
                
                if (speciesFilter || breedFilter || ageFilter || sizeFilter || genderFilter || searchTerm) {
                    const petCards = document.querySelectorAll('.pet-card');
                    let visibleCount = 0;
                    
                    petCards.forEach(card => {
                        const petName = card.querySelector('h3').textContent.toLowerCase();
                        const petSpecies = card.querySelector('.text-[#2B2B2B].font-medium').textContent.toLowerCase();
                        const petBreed = card.querySelector('.text-[#666].text-sm').textContent.toLowerCase();
                        const petAgeText = card.querySelector('.grid.grid-cols-2 .font-medium').textContent.toLowerCase();
                        const petSize = card.querySelectorAll('.grid.grid-cols-2 .font-medium')[1].textContent.toLowerCase();
                        const petGenderElement = card.querySelector('.absolute.top-3.right-3 span');
                        const petGender = petGenderElement.textContent.toLowerCase().includes('male') ? 'male' : 'female';
                        
                        // Parse age from text (e.g., "3 years")
                        let petAge = null;
                        const ageMatch = petAgeText.match(/(\d+)/);
                        if (ageMatch) {
                            petAge = parseInt(ageMatch[1]);
                        }
                        
                        // Determine age category
                        let petAgeCategory = '';
                        if (petAge !== null) {
                            if (petAge <= 1) petAgeCategory = 'baby';
                            else if (petAge <= 3) petAgeCategory = 'young';
                            else if (petAge <= 8) petAgeCategory = 'adult';
                            else petAgeCategory = 'senior';
                        }
                        
                        let shouldShow = true;
                        
                        // Apply species filter
                        if (speciesFilter && speciesFilter.trim() !== '') {
                            if (petSpecies !== speciesFilter.toLowerCase()) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply breed filter
                        if (breedFilter && breedFilter.trim() !== '') {
                            if (!petBreed.includes(breedFilter.toLowerCase())) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply age filter
                        if (ageFilter && ageFilter.trim() !== '') {
                            if (petAgeCategory !== ageFilter.toLowerCase()) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply size filter
                        if (sizeFilter && sizeFilter.trim() !== '') {
                            if (petSize !== sizeFilter.toLowerCase()) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply gender filter
                        if (genderFilter && genderFilter.trim() !== '') {
                            if (petGender !== genderFilter.toLowerCase()) {
                                shouldShow = false;
                            }
                        }
                        
                        // Apply search filter
                        if (searchTerm && searchTerm.trim() !== '') {
                            const searchLower = searchTerm.toLowerCase();
                            if (!petName.includes(searchLower) && 
                                !petSpecies.includes(searchLower) && 
                                !petBreed.includes(searchLower)) {
                                shouldShow = false;
                            }
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
                        const container = document.getElementById('petsContainer');
                        container.innerHTML = `
                            <div class="col-span-1 md:col-span-2 lg:col-span-4 text-center py-12">
                                <i class="fas fa-search text-5xl text-[#E5E5E5] mb-4"></i>
                                <h3 class="text-xl font-semibold text-[#2B2B2B] mb-2">No pets match your filter criteria</h3>
                                <p class="text-[#666]">Try adjusting your filters to find more pets.</p>
                            </div>
                        `;
                    }
                }
            }

            // Reset filters
            function resetFilters() {
                // Clear form inputs
                document.querySelectorAll('#filterForm select, #filterForm input').forEach(element => {
                    if (element.type === 'text') {
                        element.value = '';
                    } else if (element.tagName === 'SELECT') {
                        element.value = '';
                    }
                });
                
                // Submit the form to reload page without filters
                filterForm.submit();
            }

            // Attach event listeners
            function attachEventListeners() {
                resetFilterBtn.addEventListener('click', resetFilters);

                // Add Enter key support for search
                const searchFilter = document.getElementById('searchFilter');
                if (searchFilter) {
                    searchFilter.addEventListener('keyup', (e) => {
                        if (e.key === 'Enter') {
                            filterForm.submit();
                        }
                    });
                }
            }
        </script>

    </body>
</html>

<%!
    // Helper method to get age category
    private String getAgeCategory(Integer age) {
        if (age == null) return "unknown";
        if (age <= 1) return "baby";
        if (age <= 3) return "young";
        if (age <= 8) return "adult";
        return "senior";
    }
    
    // Helper method to get species icon - DIPERBAIKI: ganti switch dengan if-else
    private String getSpeciesIcon(String species) {
        if (species == null) return "fa-paw";
        
        String speciesLower = species.toLowerCase();
        if ("dog".equals(speciesLower)) {
            return "fa-paw";
        } else if ("cat".equals(speciesLower)) {
            return "fa-cat";
        } else if ("rabbit".equals(speciesLower)) {
            return "fa-rabbit";
        } else if ("bird".equals(speciesLower)) {
            return "fa-dove";
        } else {
            return "fa-paw";
        }
    }
    
    // Helper method to capitalize first letter
    private String capitalizeFirstLetter(String input) {
        if (input == null || input.isEmpty()) return "";
        return input.substring(0, 1).toUpperCase() + input.substring(1).toLowerCase();
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