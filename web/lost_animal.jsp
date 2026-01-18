<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>

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
    
    // Get current user ID from session
    Integer userId = SessionUtil.getUserId(session);
    String userName = SessionUtil.getUserName(session);
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Lost & Found Pets - Rimba Adopt</title>
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

            /* Modal styles */
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
                max-width: 700px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
            }

            /* Animation for modal */
            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }

            @keyframes slideUp {
                from { transform: translateY(50px); opacity: 0; }
                to { transform: translateY(0); opacity: 1; }
            }

            .modal-overlay.show {
                display: flex;
                animation: fadeIn 0.3s ease;
            }

            .modal-content.show {
                animation: slideUp 0.3s ease;
            }

            /* Status badges */
            .status-lost {
                background-color: #B84A4A;
                color: white;
            }

            .status-found {
                background-color: #6DBF89;
                color: #06321F;
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
            
            /* Loading spinner */
            .loading-spinner {
                border: 4px solid #f3f3f3;
                border-top: 4px solid #2F5D50;
                border-radius: 50%;
                width: 40px;
                height: 40px;
                animation: spin 1s linear infinite;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            /* Error message */
            .error-message {
                background-color: #FEE2E2;
                border: 1px solid #FCA5A5;
                color: #7F1D1D;
                padding: 1rem;
                border-radius: 0.5rem;
                margin-bottom: 1rem;
            }
            
            /* Success message */
            .success-message {
                background-color: #D1FAE5;
                border: 1px solid #A7F3D0;
                color: #065F46;
                padding: 1rem;
                border-radius: 0.5rem;
                margin-bottom: 1rem;
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
                    <h1 class="text-3xl font-bold text-[#2F5D50] border-b-2 border-[#E5E5E5] pb-4">Lost & Found Pets</h1>
                    <p class="text-[#2B2B2B] mt-2">Help reunite lost pets with their families. Report sightings or search for missing pets.</p>
                </div>

                <!-- Loading and Error Messages -->
                <div id="loadingIndicator" class="hidden mb-6">
                    <div class="flex items-center justify-center py-8">
                        <div class="loading-spinner"></div>
                        <span class="ml-3 text-[#2F5D50] font-medium">Loading lost reports...</span>
                    </div>
                </div>
                
                <div id="errorMessage" class="hidden error-message"></div>
                <div id="successMessage" class="hidden success-message"></div>

                <!-- Filter Section -->
                <div class="mb-8 p-6 bg-[#F9F9F9] rounded-lg border border-[#E5E5E5]">
                    <h2 class="text-xl font-semibold text-[#2F5D50] mb-4">Filter Lost Reports</h2>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        <!-- Status Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Status</label>
                            <select id="statusFilter" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Status</option>
                                <option value="lost">Lost</option>
                                <option value="found">Found</option>
                            </select>
                        </div>

                        <!-- Species Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Species</label>
                            <select id="speciesFilter" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">All Species</option>
                                <option value="dog">Dog</option>
                                <option value="cat">Cat</option>
                                <option value="rabbit">Rabbit</option>
                                <option value="bird">Bird</option>
                                <option value="other">Other</option>
                            </select>
                        </div>

                        <!-- Location Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Last Seen Location</label>
                            <input type="text" id="locationFilter" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Enter location...">
                        </div>

                        <!-- Date Filter -->
                        <div>
                            <label class="block text-[#2B2B2B] mb-2 font-medium">Last Seen (Days)</label>
                            <select id="dateFilter" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                                <option value="">Any Time</option>
                                <option value="1">Last 24 Hours</option>
                                <option value="3">Last 3 Days</option>
                                <option value="7">Last Week</option>
                                <option value="30">Last Month</option>
                            </select>
                        </div>
                    </div>

                    <!-- Filter Buttons -->
                    <div class="flex justify-end gap-3 mt-6">
                        <button id="applyFilter" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                            <i class="fas fa-filter mr-2"></i>Apply Filters
                        </button>
                        <button id="resetFilter" class="px-6 py-3 bg-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#D5D5D5] transition duration-300">
                            <i class="fas fa-redo mr-2"></i>Reset
                        </button>
                        <button id="reportLostBtn" class="px-6 py-3 bg-[#B84A4A] text-white font-medium rounded-lg hover:bg-[#9A3A3A] transition duration-300">
                            <i class="fas fa-exclamation-triangle mr-2"></i>Report Lost Pet
                        </button>
                    </div>
                </div>

                <!-- Results Count -->
                <div class="flex justify-between items-center mb-6">
                    <p class="text-[#2B2B2B]">
                        Showing <span id="resultCount" class="font-semibold">0</span> lost reports
                    </p>
                    <div class="text-[#2B2B2B]">
                        Page <span id="currentPage" class="font-semibold">1</span> of <span id="totalPages" class="font-semibold">1</span>
                    </div>
                </div>

                <!-- Lost Pets Grid (4x2 layout) -->
                <div id="lostPetsContainer" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <!-- Lost pet cards will be dynamically generated by JavaScript -->
                </div>

                <!-- Pagination -->
                <div id="paginationContainer" class="hidden flex justify-center items-center mt-8">
                    <nav class="flex items-center space-x-2">
                        <button id="prevPage" class="p-3 rounded-lg border border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7] disabled:opacity-50 disabled:cursor-not-allowed">
                            <i class="fas fa-chevron-left"></i>
                        </button>

                        <div id="pageNumbers" class="flex space-x-2">
                            <!-- Page numbers will be generated here -->
                        </div>

                        <button id="nextPage" class="p-3 rounded-lg border border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7]">
                            <i class="fas fa-chevron-right"></i>
                        </button>
                    </nav>
                </div>

            </div>
        </main>

        <!-- Lost Pet Details Modal -->
        <div id="lostPetModal" class="modal-overlay">
            <div class="modal-content p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold text-[#2B2B2B]" id="modalTitle">Lost Pet Details</h3>
                    <button id="closeModal" class="text-[#888] hover:text-[#2B2B2B]">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <div id="modalContent">
                    <!-- Modal content will be generated by JavaScript -->
                </div>
            </div>
        </div>

        <!-- Report Lost Pet Modal -->
        <div id="reportLostModal" class="modal-overlay">
            <div class="modal-content p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold text-[#2B2B2B]">Report Lost Pet</h3>
                    <button id="closeReportModal" class="text-[#888] hover:text-[#2B2B2B]">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <form id="reportLostForm">
                    <div class="mb-6">
                        <div class="bg-[#F0F7F4] p-4 rounded-lg mb-4">
                            <p class="text-sm text-[#666]"><i class="fas fa-info-circle mr-2 text-[#2F5D50]"></i> Fill out this form to report a lost pet. Your information will be shared with the community to help find your pet.</p>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div>
                            <label for="petName" class="block text-[#2B2B2B] mb-2 font-medium">Pet Name *</label>
                            <input type="text" id="petName" name="pet_name" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Enter pet's name" required>
                        </div>

                        <div>
                            <label for="petSpecies" class="block text-[#2B2B2B] mb-2 font-medium">Species *</label>
                            <select id="petSpecies" name="species" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" required>
                                <option value="">Select Species</option>
                                <option value="dog">Dog</option>
                                <option value="cat">Cat</option>
                                <option value="rabbit">Rabbit</option>
                                <option value="bird">Bird</option>
                                <option value="other">Other</option>
                            </select>
                        </div>

                        <div>
                            <label for="lastSeenDate" class="block text-[#2B2B2B] mb-2 font-medium">Last Seen Date *</label>
                            <input type="date" id="lastSeenDate" name="last_seen_date" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" required>
                        </div>

                        <div>
                            <label for="lastSeenTime" class="block text-[#2B2B2B] mb-2 font-medium">Last Seen Time (Approx)</label>
                            <input type="time" id="lastSeenTime" name="last_seen_time" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]">
                        </div>
                    </div>

                    <div class="mb-6">
                        <label for="lastSeenLocation" class="block text-[#2B2B2B] mb-2 font-medium">Last Seen Location *</label>
                        <input type="text" id="lastSeenLocation" name="last_seen_location" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="e.g., Taman Tun Dr Ismail, Kuala Lumpur" required>
                    </div>

                    <div class="mb-6">
                        <label for="petDescription" class="block text-[#2B2B2B] mb-2 font-medium">Description *</label>
                        <textarea id="petDescription" name="description" rows="4" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Describe your pet (color, size, distinctive marks, collar color, etc.)..." required></textarea>
                    </div>

                    <div class="mb-6">
                        <label for="contactInfo" class="block text-[#2B2B2B] mb-2 font-medium">Your Contact Information *</label>
                        <textarea id="contactInfo" name="contact_info" rows="3" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Phone number, email, or other contact details..." required></textarea>
                        <p class="text-[#888] text-sm mt-1">This information will be visible to users who may have found your pet.</p>
                    </div>

                    <div class="mb-6">
                        <label class="block text-[#2B2B2B] mb-2 font-medium">Upload Photo (Optional)</label>
                        <div class="border-2 border-dashed border-[#E5E5E5] rounded-lg p-6 text-center">
                            <i class="fas fa-cloud-upload-alt text-3xl text-[#888] mb-3"></i>
                            <p class="text-[#666] mb-2">Drag & drop or click to upload photo</p>
                            <p class="text-[#888] text-sm">Recommended: Clear photo of your pet (max 5MB)</p>
                            <input type="file" id="petPhoto" name="photo" class="hidden" accept="image/*">
                            <button type="button" id="uploadPhotoBtn" class="mt-3 px-4 py-2 bg-[#F6F3E7] text-[#2B2B2B] rounded-lg hover:bg-[#E5E5E5]">
                                Choose File
                            </button>
                        </div>
                    </div>

                    <div class="flex justify-end space-x-3">
                        <button type="button" id="cancelReport" class="px-6 py-3 border border-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#F6F3E7]">
                            Cancel
                        </button>
                        <button type="submit" id="submitReportBtn" class="px-6 py-3 bg-[#B84A4A] text-white font-medium rounded-lg hover:bg-[#9A3A3A] transition duration-300">
                            <i class="fas fa-paper-plane mr-2"></i> Submit Report
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
            // Store current user info from JSP
            const currentUserId = <%= userId %>;
            const currentUserName = "<%= userName != null ? userName : "User" %>";
            
            // Global variables
            let lostPets = [];
            let currentPage = 1;
            const itemsPerPage = 8;
            let filteredLostPets = [];
            let totalPages = 1;
            let totalReports = 0;

            // DOM Elements
            const lostPetsContainer = document.getElementById('lostPetsContainer');
            const resultCount = document.getElementById('resultCount');
            const currentPageSpan = document.getElementById('currentPage');
            const totalPagesSpan = document.getElementById('totalPages');
            const prevPageBtn = document.getElementById('prevPage');
            const nextPageBtn = document.getElementById('nextPage');
            const pageNumbers = document.getElementById('pageNumbers');
            const paginationContainer = document.getElementById('paginationContainer');
            const applyFilterBtn = document.getElementById('applyFilter');
            const resetFilterBtn = document.getElementById('resetFilter');
            const reportLostBtn = document.getElementById('reportLostBtn');
            const statusFilter = document.getElementById('statusFilter');
            const speciesFilter = document.getElementById('speciesFilter');
            const locationFilter = document.getElementById('locationFilter');
            const dateFilter = document.getElementById('dateFilter');
            const loadingIndicator = document.getElementById('loadingIndicator');
            const errorMessage = document.getElementById('errorMessage');
            const successMessage = document.getElementById('successMessage');

            // Modal elements
            const lostPetModal = document.getElementById('lostPetModal');
            const modalTitle = document.getElementById('modalTitle');
            const modalContent = document.getElementById('modalContent');
            const closeModalBtn = document.getElementById('closeModal');

            // Report modal elements
            const reportLostModal = document.getElementById('reportLostModal');
            const closeReportModalBtn = document.getElementById('closeReportModal');
            const cancelReport = document.getElementById('cancelReport');
            const reportLostForm = document.getElementById('reportLostForm');
            const submitReportBtn = document.getElementById('submitReportBtn');
            const uploadPhotoBtn = document.getElementById('uploadPhotoBtn');
            const petPhoto = document.getElementById('petPhoto');

            // Initialize
            document.addEventListener('DOMContentLoaded', function () {
                loadLostReports();
                attachEventListeners();

                // Set today's date as max for date input
                const today = new Date().toISOString().split('T')[0];
                document.getElementById('lastSeenDate').max = today;
            });

            // Load lost reports from backend
            async function loadLostReports() {
                showLoading(true);
                hideMessages();
                
                try {
                    const response = await fetch('ManageLostAnimalServlet?action=getAll&page=' + currentPage + '&limit=' + itemsPerPage);
                    const data = await response.json();
                    
                    if (data.success) {
                        lostPets = data.reports || [];
                        filteredLostPets = [...lostPets];
                        totalReports = data.total || 0;
                        totalPages = data.totalPages || 1;
                        
                        renderLostPets();
                        updatePagination();
                        showSuccess('Successfully loaded ' + totalReports + ' lost reports');
                    } else {
                        showError(data.message || 'Failed to load lost reports');
                    }
                } catch (error) {
                    console.error('Error loading lost reports:', error);
                    showError('Network error. Please check your connection.');
                } finally {
                    showLoading(false);
                }
            }

            // Search lost reports with filters
            async function searchLostReports() {
                showLoading(true);
                hideMessages();
                
                try {
                    const params = new URLSearchParams({
                        action: 'search',
                        status: statusFilter.value,
                        species: speciesFilter.value,
                        location: locationFilter.value,
                        dateFilter: dateFilter.value
                    });
                    
                    const response = await fetch('ManageLostAnimalServlet?' + params.toString());
                    const data = await response.json();
                    
                    if (data.success) {
                        filteredLostPets = data.reports || [];
                        totalReports = data.count || 0;
                        totalPages = Math.ceil(totalReports / itemsPerPage);
                        currentPage = 1;
                        
                        renderLostPets();
                        updatePagination();
                    } else {
                        showError(data.message || 'Failed to search lost reports');
                    }
                } catch (error) {
                    console.error('Error searching lost reports:', error);
                    showError('Network error. Please check your connection.');
                } finally {
                    showLoading(false);
                }
            }

            // Get lost report details by ID
            async function getLostReportDetails(lostId) {
                showLoading(true);
                
                try {
                    const response = await fetch('ManageLostAnimalServlet?action=getById&lostId=' + lostId);
                    const data = await response.json();
                    
                    if (data.success) {
                        return data.report;
                    } else {
                        showError(data.message || 'Failed to load report details');
                        return null;
                    }
                } catch (error) {
                    console.error('Error loading report details:', error);
                    showError('Network error. Please check your connection.');
                    return null;
                } finally {
                    showLoading(false);
                }
            }

            // Render lost pets for current page
            function renderLostPets() {
                const startIndex = (currentPage - 1) * itemsPerPage;
                const endIndex = startIndex + itemsPerPage;
                const pagePets = filteredLostPets.slice(startIndex, endIndex);

                lostPetsContainer.innerHTML = '';

                if (pagePets.length === 0) {
                    lostPetsContainer.innerHTML = '' +
                            '<div class="col-span-1 md:col-span-2 lg:col-span-4 text-center py-12">' +
                            '<i class="fas fa-search text-5xl text-[#E5E5E5] mb-4"></i>' +
                            '<h3 class="text-xl font-semibold text-[#2B2B2B] mb-2">No lost pets found</h3>' +
                            '<p class="text-[#666]">Try adjusting your filters or report a lost pet.</p>' +
                            '</div>';
                    resultCount.textContent = '0';
                    paginationContainer.classList.add('hidden');
                    return;
                }

                pagePets.forEach(function (pet) {
                    const card = createLostPetCard(pet);
                    lostPetsContainer.appendChild(card);
                });

                resultCount.textContent = filteredLostPets.length;
                paginationContainer.classList.remove('hidden');
            }

            // Create lost pet card HTML
            function createLostPetCard(pet) {
                const card = document.createElement('div');
                card.className = 'lost-pet-card bg-white rounded-xl border border-[#E5E5E5] overflow-hidden card-hover';
                card.dataset.id = pet.lost_id;

                // Format date
                const lastSeenDate = new Date(pet.last_seen_date);
                const formattedDate = lastSeenDate.toLocaleDateString('en-US', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                });

                // Calculate days ago
                const today = new Date();
                const timeDiff = today - lastSeenDate;
                const daysAgo = Math.floor(timeDiff / (1000 * 60 * 60 * 24));

                // Get species icon
                const speciesIcon = getSpeciesIcon(pet.species);

                card.innerHTML = '' +
                        '<div class="relative">' +
                        '<img src="' + (pet.photo_path || 'animal_picture/default_lost_pet.jpg') + '" alt="' + pet.pet_name + '" class="w-full h-48 object-cover">' +
                        '<div class="absolute top-3 right-3">' +
                        '<span class="px-3 py-1 rounded-full text-sm font-medium ' + (pet.status === 'lost' ? 'status-lost' : 'status-found') + '">' +
                        '<i class="fas ' + (pet.status === 'lost' ? 'fa-search' : 'fa-check-circle') + ' mr-1"></i> ' + (pet.status === 'lost' ? 'Lost' : 'Found') +
                        '</span>' +
                        '</div>' +
                        '<div class="absolute bottom-3 left-3 bg-black/70 text-white px-3 py-1 rounded-full text-sm">' +
                        (daysAgo === 0 ? 'Today' : daysAgo + ' day' + (daysAgo !== 1 ? 's' : '') + ' ago') +
                        '</div>' +
                        '</div>' +
                        '<div class="p-5">' +
                        '<h3 class="text-xl font-bold text-[#2B2B2B] mb-2">' + pet.pet_name + '</h3>' +
                        '<div class="flex items-center mb-3">' +
                        '<div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">' +
                        '<i class="fas ' + speciesIcon + ' text-[#2F5D50]"></i>' +
                        '</div>' +
                        '<div>' +
                        '<p class="text-[#2B2B2B] font-medium">' + capitalizeFirstLetter(pet.species) + '</p>' +
                        '<p class="text-[#666] text-sm">' + (pet.breed || 'Unknown breed') + '</p>' +
                        '</div>' +
                        '</div>' +
                        '<div class="mb-4">' +
                        '<div class="flex items-start mb-2">' +
                        '<i class="fas fa-map-marker-alt text-[#2F5D50] mt-1 mr-2"></i>' +
                        '<p class="text-[#666] text-sm flex-1">' + (pet.last_seen_location || 'Location not specified') + '</p>' +
                        '</div>' +
                        '<div class="flex items-center">' +
                        '<i class="far fa-calendar text-[#2F5D50] mr-2"></i>' +
                        '<p class="text-[#666] text-sm">' + formattedDate + '</p>' +
                        '</div>' +
                        '</div>' +
                        '<p class="text-[#666] text-sm mb-4 line-clamp-2">' + (pet.description || 'No description available') + '</p>' +
                        '<button class="view-details-btn w-full text-center py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300" data-id="' + pet.lost_id + '">' +
                        '<i class="fas fa-info-circle mr-2"></i> View Details' +
                        '</button>' +
                        '</div>';

                return card;
            }

            // Get icon for species
            function getSpeciesIcon(species) {
                switch (species) {
                    case 'dog':
                        return 'fa-paw';
                    case 'cat':
                        return 'fa-cat';
                    case 'rabbit':
                        return 'fa-rabbit';
                    case 'bird':
                        return 'fa-dove';
                    default:
                        return 'fa-paw';
                }
            }

            // Capitalize first letter
            function capitalizeFirstLetter(string) {
                return string.charAt(0).toUpperCase() + string.slice(1);
            }

            // Show lost pet details in modal
            async function showLostPetDetails(petId) {
                showLoading(true);
                
                try {
                    const pet = await getLostReportDetails(petId);
                    if (!pet) return;
                    
                    // Format dates
                    const lastSeenDate = new Date(pet.last_seen_date);
                    const formattedDate = lastSeenDate.toLocaleDateString('en-US', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    });

                    const reportedDate = new Date(pet.created_at);
                    const reportedFormatted = reportedDate.toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                    });

                    modalTitle.textContent = pet.pet_name + ' - ' + (pet.status === 'lost' ? 'Lost' : 'Found') + ' ' + capitalizeFirstLetter(pet.species);

                    modalContent.innerHTML = '' +
                            '<div class="mb-6">' +
                            '<div class="mb-4">' +
                            '<img src="' + (pet.photo_path || 'animal_picture/default_lost_pet.jpg') + '" alt="' + pet.pet_name + '" class="w-full h-64 object-cover rounded-xl">' +
                            '</div>' +
                            '<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">' +
                            '<div class="bg-[#F9F9F9] p-5 rounded-xl">' +
                            '<h4 class="font-semibold text-[#2B2B2B] mb-3">Pet Information</h4>' +
                            '<div class="space-y-3">' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Name</span>' +
                            '<span class="font-medium">' + pet.pet_name + '</span>' +
                            '</div>' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Species</span>' +
                            '<span class="font-medium">' + capitalizeFirstLetter(pet.species) + '</span>' +
                            '</div>' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Status</span>' +
                            '<span class="font-medium ' + (pet.status === 'lost' ? 'text-[#B84A4A]' : 'text-[#6DBF89]') + '">' +
                            (pet.status === 'lost' ? 'Lost' : 'Found') +
                            '</span>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '<div class="bg-[#F9F9F9] p-5 rounded-xl">' +
                            '<h4 class="font-semibold text-[#2B2B2B] mb-3">Last Seen Details</h4>' +
                            '<div class="space-y-3">' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Date</span>' +
                            '<span class="font-medium">' + formattedDate + '</span>' +
                            '</div>' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Location</span>' +
                            '<span class="font-medium">' + (pet.last_seen_location || 'Not specified') + '</span>' +
                            '</div>' +
                            '<div class="flex justify-between">' +
                            '<span class="text-[#666]">Reported</span>' +
                            '<span class="font-medium">' + reportedFormatted + '</span>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '<div class="mb-6">' +
                            '<h4 class="font-semibold text-[#2B2B2B] mb-2">Description</h4>' +
                            '<p class="text-[#666] leading-relaxed whitespace-pre-line">' + (pet.description || 'No description available') + '</p>' +
                            '</div>' +
                            '<div class="mb-6">' +
                            '<h4 class="font-semibold text-[#2B2B2B] mb-2">Owner Information</h4>' +
                            '<div class="bg-[#F0F7F4] p-4 rounded-lg">' +
                            '<div class="space-y-2">' +
                            '<div class="flex items-center">' +
                            '<i class="fas fa-user text-[#2F5D50] mr-3"></i>' +
                            '<span class="font-medium">' + (pet.adopter_name || 'Unknown') + '</span>' +
                            '</div>' +
                            '<div class="flex items-center">' +
                            '<i class="fas fa-phone-alt text-[#2F5D50] mr-3"></i>' +
                            '<span>' + (pet.adopter_phone || 'No contact provided') + '</span>' +
                            '</div>' +
                            '<div class="flex items-center">' +
                            '<i class="fas fa-envelope text-[#2F5D50] mr-3"></i>' +
                            '<span>' + (pet.adopter_email || 'No email provided') + '</span>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '<div class="flex justify-end space-x-3">' +
                            '<button type="button" id="reportSightingBtn" class="px-6 py-3 bg-[#6DBF89] text-[#06321F] font-medium rounded-lg hover:bg-[#57A677] transition duration-300">' +
                            '<i class="fas fa-eye mr-2"></i> Report Sighting' +
                            '</button>';
                    
                    // Only show "Mark as Found" button if the pet is lost AND current user is the owner
                    if (pet.status === 'lost' && pet.adopter_id === currentUserId) {
                        modalContent.innerHTML += '<button type="button" id="foundPetBtn" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">' +
                                '<i class="fas fa-check-circle mr-2"></i> Mark as Found' +
                                '</button>';
                    }
                    
                    modalContent.innerHTML += '</div>';
                    
                    openModal();

                    // Add event listeners for modal buttons after rendering
                    setTimeout(function () {
                        const reportSightingBtn = document.getElementById('reportSightingBtn');
                        if (reportSightingBtn) {
                            reportSightingBtn.addEventListener('click', function () {
                                alert('Thank you for reporting a sighting of ' + pet.pet_name + '! The owner has been notified.');
                                closeModal();
                            });
                        }

                        const foundPetBtn = document.getElementById('foundPetBtn');
                        if (foundPetBtn) {
                            foundPetBtn.addEventListener('click', async function () {
                                if (confirm('Are you sure you want to mark ' + pet.pet_name + ' as found?')) {
                                    await updateLostReportStatus(pet.lost_id, 'found');
                                    closeModal();
                                }
                            });
                        }
                    }, 100);
                    
                } catch (error) {
                    console.error('Error showing lost pet details:', error);
                    showError('Failed to load pet details');
                } finally {
                    showLoading(false);
                }
            }

            // Update lost report status
            async function updateLostReportStatus(lostId, status) {
                showLoading(true);
                
                try {
                    const formData = new FormData();
                    formData.append('lostId', lostId);
                    formData.append('status', status);
                    formData.append('action', 'updateStatus');
                    
                    const response = await fetch('ManageLostAnimalServlet', {
                        method: 'POST',
                        body: new URLSearchParams(formData)
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        showSuccess(data.message);
                        // Reload the reports
                        await loadLostReports();
                    } else {
                        showError(data.message);
                    }
                } catch (error) {
                    console.error('Error updating status:', error);
                    showError('Network error. Please check your connection.');
                } finally {
                    showLoading(false);
                }
            }

            // Open modal
            function openModal() {
                lostPetModal.classList.add('show');
                setTimeout(function () {
                    const modalContentEl = lostPetModal.querySelector('.modal-content');
                    modalContentEl.classList.add('show');
                }, 10);
            }

            // Close modal
            function closeModal() {
                const modalContentEl = lostPetModal.querySelector('.modal-content');
                modalContentEl.classList.remove('show');

                setTimeout(function () {
                    lostPetModal.classList.remove('show');
                }, 300);
            }

            // Open report modal
            function openReportModal() {
                reportLostModal.classList.add('show');
                setTimeout(function () {
                    const modalContentEl = reportLostModal.querySelector('.modal-content');
                    modalContentEl.classList.add('show');
                }, 10);
            }

            // Close report modal
            function closeReportModal() {
                const modalContentEl = reportLostModal.querySelector('.modal-content');
                modalContentEl.classList.remove('show');

                setTimeout(function () {
                    reportLostModal.classList.remove('show');
                    resetReportForm();
                }, 300);
            }

            // Reset report form
            function resetReportForm() {
                reportLostForm.reset();
            }

            // Update pagination controls
            function updatePagination() {
                totalPages = Math.ceil(filteredLostPets.length / itemsPerPage);

                currentPageSpan.textContent = currentPage;
                totalPagesSpan.textContent = totalPages;

                // Update button states
                prevPageBtn.disabled = currentPage === 1 || totalPages === 0;
                nextPageBtn.disabled = currentPage === totalPages || totalPages === 0;

                // Generate page number buttons
                pageNumbers.innerHTML = '';
                const maxVisiblePages = 5;
                let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
                let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

                if (endPage - startPage + 1 < maxVisiblePages) {
                    startPage = Math.max(1, endPage - maxVisiblePages + 1);
                }

                for (let i = startPage; i <= endPage; i++) {
                    const pageBtn = document.createElement('button');
                    pageBtn.className = 'page-btn w-10 h-10 rounded-lg border ' +
                            (i === currentPage ? 'border-[#2F5D50] bg-[#2F5D50] text-white' : 'border-[#E5E5E5] text-[#2B2B2B] hover:bg-[#F6F3E7]');
                    pageBtn.textContent = i;

                    // Use closure to capture i value
                    pageBtn.addEventListener('click', (function (pageNum) {
                        return function () {
                            currentPage = pageNum;
                            renderLostPets();
                            updatePagination();
                            window.scrollTo({top: 0, behavior: 'smooth'});
                        };
                    })(i));

                    pageNumbers.appendChild(pageBtn);
                }
            }

            // Apply filters
            function applyFilters() {
                searchLostReports();
            }

            // Reset filters
            function resetFilters() {
                statusFilter.value = '';
                speciesFilter.value = '';
                locationFilter.value = '';
                dateFilter.value = '';
                currentPage = 1;
                loadLostReports();
            }

            // Handle report form submission
            async function handleReportSubmit(e) {
                e.preventDefault();
                
                // Get form values
                const petName = document.getElementById('petName').value.trim();
                const petSpecies = document.getElementById('petSpecies').value;
                const lastSeenDate = document.getElementById('lastSeenDate').value;
                const lastSeenTime = document.getElementById('lastSeenTime').value;
                const lastSeenLocation = document.getElementById('lastSeenLocation').value.trim();
                const petDescription = document.getElementById('petDescription').value.trim();
                const contactInfo = document.getElementById('contactInfo').value.trim();

                if (!petName || !petSpecies || !lastSeenDate || !lastSeenLocation || !petDescription || !contactInfo) {
                    showError('Please fill all required fields (*)');
                    return;
                }

                // Disable submit button and show loading
                submitReportBtn.disabled = true;
                submitReportBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Submitting...';

                try {
                    const formData = new FormData();
                    formData.append('action', 'create');
                    formData.append('pet_name', petName);
                    formData.append('species', petSpecies);
                    formData.append('last_seen_date', lastSeenDate);
                    formData.append('last_seen_location', lastSeenLocation);
                    formData.append('description', petDescription);
                    formData.append('contact_info', contactInfo);
                    
                    // Handle file upload if exists
                    if (petPhoto.files.length > 0) {
                        formData.append('photo', petPhoto.files[0]);
                    }

                    const response = await fetch('ManageLostAnimalServlet', {
                        method: 'POST',
                        body: formData
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        showSuccess('Report submitted successfully! ' + petName + ' has been added to lost pets list.');
                        closeReportModal();
                        // Reload the reports
                        await loadLostReports();
                    } else {
                        showError(data.message || 'Failed to submit report');
                    }
                } catch (error) {
                    console.error('Error submitting report:', error);
                    showError('Network error. Please check your connection.');
                } finally {
                    // Re-enable submit button
                    submitReportBtn.disabled = false;
                    submitReportBtn.innerHTML = '<i class="fas fa-paper-plane mr-2"></i> Submit Report';
                }
            }

            // Show/hide loading indicator
            function showLoading(show) {
                if (show) {
                    loadingIndicator.classList.remove('hidden');
                } else {
                    loadingIndicator.classList.add('hidden');
                }
            }

            // Show error message
            function showError(message) {
                errorMessage.textContent = message;
                errorMessage.classList.remove('hidden');
                setTimeout(() => errorMessage.classList.add('hidden'), 5000);
            }

            // Show success message
            function showSuccess(message) {
                successMessage.textContent = message;
                successMessage.classList.remove('hidden');
                setTimeout(() => successMessage.classList.add('hidden'), 5000);
            }

            // Hide all messages
            function hideMessages() {
                errorMessage.classList.add('hidden');
                successMessage.classList.add('hidden');
            }

            // Attach event listeners
            function attachEventListeners() {
                applyFilterBtn.addEventListener('click', applyFilters);
                resetFilterBtn.addEventListener('click', resetFilters);
                reportLostBtn.addEventListener('click', openReportModal);

                prevPageBtn.addEventListener('click', function () {
                    if (currentPage > 1) {
                        currentPage--;
                        renderLostPets();
                        updatePagination();
                        window.scrollTo({top: 0, behavior: 'smooth'});
                    }
                });

                nextPageBtn.addEventListener('click', function () {
                    if (currentPage < totalPages) {
                        currentPage++;
                        renderLostPets();
                        updatePagination();
                        window.scrollTo({top: 0, behavior: 'smooth'});
                    }
                });

                // Close modals
                closeModalBtn.addEventListener('click', closeModal);
                closeReportModalBtn.addEventListener('click', closeReportModal);
                cancelReport.addEventListener('click', closeReportModal);

                // Close modal when clicking outside
                lostPetModal.addEventListener('click', function (e) {
                    if (e.target === lostPetModal) {
                        closeModal();
                    }
                });

                reportLostModal.addEventListener('click', function (e) {
                    if (e.target === reportLostModal) {
                        closeReportModal();
                    }
                });

                // View details button click (event delegation)
                lostPetsContainer.addEventListener('click', function (e) {
                    const target = e.target;
                    if (target.classList.contains('view-details-btn') || target.closest('.view-details-btn')) {
                        const button = target.classList.contains('view-details-btn') ? target : target.closest('.view-details-btn');
                        const petId = button.dataset.id;
                        showLostPetDetails(petId);
                    }
                });

                // Upload photo button
                uploadPhotoBtn.addEventListener('click', function () {
                    petPhoto.click();
                });

                petPhoto.addEventListener('change', function (e) {
                    if (e.target.files && e.target.files[0]) {
                        const fileName = e.target.files[0].name;
                        uploadPhotoBtn.innerHTML = '<i class="fas fa-check mr-2"></i>' + fileName;
                        uploadPhotoBtn.classList.add('bg-[#6DBF89]', 'text-white');
                    }
                });

                // Report form submission
                reportLostForm.addEventListener('submit', handleReportSubmit);

                // Add Enter key support for filters
                const filters = [statusFilter, speciesFilter, locationFilter, dateFilter];
                filters.forEach(function (filter) {
                    filter.addEventListener('keyup', function (e) {
                        if (e.key === 'Enter') {
                            applyFilters();
                        }
                    });
                });
            }
        </script>

    </body>
</html>