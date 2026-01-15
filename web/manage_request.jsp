<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="java.util.*" %>
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

    // Get data from servlet
    List<Map<String, Object>> requestsData = (List<Map<String, Object>>) request.getAttribute("requestsData");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    String shelterName = (String) request.getAttribute("shelterName");

    if (requestsData == null) {
        // If data is null, redirect to servlet to load data
        response.sendRedirect("manageAdoptionServlet");
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
            .modal { transition: opacity 0.2s ease, visibility 0.2s ease; opacity: 0; visibility: hidden; }
            .modal.active { opacity: 1; visibility: visible; }
            .modal-content { transform: scale(0.95); transition: transform 0.2s ease; }
            .modal.active .modal-content { transform: scale(1); }
            .no-scrollbar::-webkit-scrollbar { display: none; }
            .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        </style>
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
                                <img src="profile_picture/shelter/pic1.png" class="w-full h-full object-cover" onerror="this.src='https://ui-avatars.com/api/?name=<%= shelterName != null ? shelterName.replace(" ", "+") : "Shelter"%>&background=2F5D50&color=fff'">
                            </div>
                            <div>
                                <h3 class="text-xl font-bold text-primary"><%= shelterName != null ? shelterName : "Shelter"%></h3>
                                <div class="text-sm text-gray-600"><i class="fas fa-map-marker-alt mr-1"></i> Kuala Lumpur, MY</div>
                            </div>
                        </div>
                        <div class="text-right">
                            <div class="text-2xl font-bold text-primary" id="pending-count"><%= pendingCount != null ? pendingCount : 0%></div>
                            <div class="text-xs text-gray-500 uppercase font-bold">Pending Requests</div>
                        </div>
                    </div>
                </div>

                <hr class="border-t border-divider my-6" />

                <div class="flex flex-col md:flex-row justify-between items-center gap-4 mb-6">
                    <div class="flex flex-wrap gap-2 w-full md:w-auto" id="filter-container">
                        <button class="filter-btn active px-5 py-2 rounded-full text-sm font-medium transition-all shadow-sm bg-primary text-white border border-primary" data-status="all">All</button>
                        <button class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all border border-chip-pending text-chip-pending hover:bg-bg-page" data-status="pending">Pending</button>
                        <button class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all border border-secondary text-secondary-dark hover:bg-bg-page" data-status="approved">Approved</button>
                        <button class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all border border-chip-rejected text-chip-rejected hover:bg-bg-page" data-status="rejected">Rejected</button>
                        <button class="filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all border border-gray-400 text-gray-500 hover:bg-bg-page" data-status="cancelled">Cancelled</button>
                    </div>

                    <div class="relative w-full md:w-80">
                        <input type="text" id="search-input" placeholder="Search pet or adopter..." class="w-full py-2.5 pl-10 pr-4 border border-divider rounded-xl focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent transition-all bg-bg-page focus:bg-white">
                        <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    </div>
                </div>

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
                        </tbody>
                    </table>
                </div>

                <div id="pagination-controls" class="flex justify-between items-center mt-6">
                    <div class="text-sm text-gray-600">
                        Showing <span id="start-index" class="font-bold text-primary">0</span> to <span id="end-index" class="font-bold text-primary">0</span> of <span id="total-items" class="font-bold text-primary">0</span>
                    </div>
                    <div class="flex gap-2">
                        <button id="prev-btn" class="px-4 py-2 text-sm rounded-lg border border-divider hover:bg-gray-100 disabled:opacity-50 transition">Previous</button>
                        <button id="next-btn" class="px-4 py-2 text-sm rounded-lg border border-divider hover:bg-gray-100 disabled:opacity-50 transition">Next</button>
                    </div>
                </div>
            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Modals (same as before) -->
        <div id="reviewModal" class="modal fixed inset-0 bg-black/60 z-40 flex items-center justify-center p-4 backdrop-blur-sm">
            <div class="modal-content bg-white rounded-2xl w-full max-w-5xl max-h-[95vh] overflow-y-auto shadow-2xl flex flex-col">

                <div class="flex justify-between items-center p-6 border-b border-divider sticky top-0 bg-white z-10">
                    <div>
                        <h3 class="text-2xl font-bold text-primary">Application Details</h3>
                        <p class="text-xs text-gray-500 font-bold uppercase tracking-wider mt-1">Request ID: #<span id="review-request-id"></span></p>
                    </div>
                    <button onclick="closeModal('reviewModal')" class="w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition text-gray-500">
                        <i class="fas fa-times text-xl"></i>
                    </button>
                </div>

                <div class="p-6 grid grid-cols-1 lg:grid-cols-3 gap-8">

                    <div class="lg:col-span-1 space-y-6">
                        <div class="bg-bg-page rounded-2xl p-6 border border-divider text-center relative overflow-hidden">
                            <div class="absolute top-0 left-0 w-full h-2 bg-primary"></div>
                            <img id="review-pet-photo" src="" class="w-28 h-28 rounded-full mx-auto object-cover border-4 border-white shadow-md mb-4">
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
                                    <span id="review-status-badge" class="inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white bg-gray-400">Pending</span>
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
                            <img id="review-adopter-photo" src="" class="w-16 h-16 rounded-xl object-cover border border-divider shadow-sm">
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
                                <textarea id="shelter-response" rows="3" class="w-full p-4 border border-divider rounded-xl focus:ring-2 focus:ring-primary focus:outline-none mb-4 text-sm bg-white shadow-sm resize-none" placeholder="Write a response to the adopter..."></textarea>

                                <div class="flex flex-col sm:flex-row justify-end gap-3">
                                    <button onclick="closeModal('reviewModal')" class="px-5 py-2.5 rounded-xl border border-divider bg-white hover:bg-gray-50 text-gray-600 font-medium transition">Cancel</button>

                                    <button onclick="promptConfirmation('reject')" class="px-6 py-2.5 rounded-xl bg-chip-rejected hover:bg-red-700 text-white font-bold shadow-md transition flex items-center justify-center">
                                        <i class="fas fa-times mr-2"></i>Reject
                                    </button>
                                    <button onclick="promptConfirmation('approve')" class="px-6 py-2.5 rounded-xl bg-primary hover:bg-primary-dark text-white font-bold shadow-md transition flex items-center justify-center">
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
                                    <button onclick="closeModal('reviewModal')" class="px-6 py-2.5 rounded-xl bg-gray-200 text-gray-800 hover:bg-gray-300 font-bold transition">Close Details</button>
                                </div>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div id="confirmationModal" class="modal fixed inset-0 bg-black/70 z-[60] flex items-center justify-center p-4 backdrop-blur-sm">
            <div class="modal-content bg-white rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center">

                <div id="confirm-icon-container" class="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 transition-colors">
                    <i id="confirm-icon" class="fas fa-question text-3xl text-white"></i>
                </div>

                <h3 class="text-xl font-bold text-text-main mb-2" id="confirm-title">Are you sure?</h3>
                <p class="text-gray-500 text-sm mb-6" id="confirm-desc">This action cannot be undone.</p>

                <div class="flex gap-3 justify-center">
                    <button onclick="closeModal('confirmationModal')" class="flex-1 py-2.5 rounded-xl border border-divider text-gray-600 font-medium hover:bg-gray-50 transition">No, Cancel</button>
                    <button id="confirm-yes-btn" class="flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90">Yes, Confirm</button>
                </div>
            </div>
        </div>

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
            // --- DATA & STATE ---
            // Convert server data to JavaScript format
            var RAW_DATA = [
            <%
                if (requestsData != null && !requestsData.isEmpty()) {
                    for (int i = 0; i < requestsData.size(); i++) {
                        Map<String, Object> item = requestsData.get(i);
            %>
            {
            id: <%= item.get("id")%>,
                    pet: "<%= escapeJavaScript((String) item.get("pet"))%>",
                    breed: "<%= escapeJavaScript((String) item.get("breed"))%>",
                    species: "<%= escapeJavaScript((String) item.get("species"))%>",
                    age: "<%= item.get("age")%>",
                    gender: "<%= escapeJavaScript((String) item.get("gender"))%>",
                    health: "<%= escapeJavaScript((String) item.get("health"))%>",
                    pet_img: "<%= escapeJavaScript((String) item.get("pet_img"))%>",
                    adopter: "<%= escapeJavaScript((String) item.get("adopter"))%>",
                    job: "<%= escapeJavaScript((String) item.get("job"))%>",
                    house: "<%= escapeJavaScript((String) item.get("house"))%>",
                    pets: <%= item.get("pets")%>,
                    notes: "<%= escapeJavaScript((String) item.get("notes"))%>",
                    msg: "<%= escapeJavaScript((String) item.get("adopter_message"))%>",
                    date: "<%= item.get("date")%>",
                    status: "<%= item.get("status")%>",
                    response: "<%= escapeJavaScript((String) item.get("shelter_response"))%>",
                    cancellation_reason: "<%= item.get("cancellation_reason") != null ? escapeJavaScript((String) item.get("cancellation_reason")) : ""%>",
                    adopter_img: "<%= escapeJavaScript((String) item.get("adopter_img"))%>",
                    adopter_email: "<%= escapeJavaScript((String) item.get("adopter_email"))%>",
                    adopter_address: "<%= escapeJavaScript((String) item.get("adopter_address"))%>"
            }<%= i < requestsData.size() - 1 ? "," : ""%>
            <%
                    }
                }
            %>
            ];

            var REQUESTS = RAW_DATA.map(function (item, index) {
                var newItem = {};
                // Copy semua property
                for (var key in item) {
                    if (item.hasOwnProperty(key)) {
                        newItem[key] = item[key];
                    }
                }
                // Handle empty images
                if (!newItem.pet_img || newItem.pet_img.trim() === "") {
                    newItem.pet_img = 'default_pet.jpg';
                }
                if (!newItem.adopter_img || newItem.adopter_img.trim() === "") {
                    newItem.adopter_img = 'default_user.jpg';
                }
                return newItem;
            });

            var state = {
                data: REQUESTS,
                filtered: [],
                page: 1,
                perPage: 10,
                filter: 'all',
                search: '',
                currentId: null,
                pendingAction: null
            };

            var els = {
                table: document.getElementById('requests-table'),
                counts: {
                    displayPending: document.getElementById('pending-count')
                }
            };

            // --- CORE FUNCTIONS ---

            function init() {
                applyFilter();
                setupEvents();
                setupPagination(); // Tambah ini
            }

            function setupPagination() {
                var prevBtn = document.getElementById('prev-btn');
                var nextBtn = document.getElementById('next-btn');

                prevBtn.addEventListener('click', function () {
                    if (state.page > 1) {
                        state.page--;
                        renderTable();
                    }
                });

                nextBtn.addEventListener('click', function () {
                    var totalPages = Math.ceil(state.filtered.length / state.perPage);
                    if (state.page < totalPages) {
                        state.page++;
                        renderTable();
                    }
                });
            }


            function setupEvents() {
                // Filter Tabs
                var filterButtons = document.querySelectorAll('.filter-btn');
                for (var i = 0; i < filterButtons.length; i++) {
                    filterButtons[i].addEventListener('click', function (e) {
                        state.filter = e.currentTarget.dataset.status;
                        state.page = 1;
                        applyFilter();
                        updateTabStyles();
                    });
                }

                // Search
                document.getElementById('search-input').addEventListener('input', function (e) {
                    state.search = e.target.value.toLowerCase().trim();
                    state.page = 1;
                    applyFilter();
                });
            }

            function updateTabStyles() {
                var filterButtons = document.querySelectorAll('.filter-btn');
                for (var i = 0; i < filterButtons.length; i++) {
                    var btn = filterButtons[i];
                    var isActive = btn.dataset.status === state.filter;
                    btn.className = 'filter-btn px-5 py-2 rounded-full text-sm font-medium transition-all border hover:bg-white';

                    if (isActive) {
                        btn.classList.add('active', 'shadow-md', 'transform', 'scale-105');
                        if (state.filter === 'all')
                            btn.classList.add('bg-primary', 'text-white', 'border-primary');
                        else if (state.filter === 'pending')
                            btn.classList.add('bg-chip-pending', 'text-white', 'border-chip-pending');
                        else if (state.filter === 'approved')
                            btn.classList.add('bg-secondary', 'text-primary-dark', 'border-secondary');
                        else if (state.filter === 'rejected')
                            btn.classList.add('bg-chip-rejected', 'text-white', 'border-chip-rejected');
                        else
                            btn.classList.add('bg-gray-500', 'text-white', 'border-gray-500');
                    } else {
                        // Inactive styles
                        if (btn.dataset.status === 'all')
                            btn.classList.add('border-primary', 'text-primary');
                        else if (btn.dataset.status === 'pending')
                            btn.classList.add('border-chip-pending', 'text-chip-pending');
                        else if (btn.dataset.status === 'approved')
                            btn.classList.add('border-secondary', 'text-secondary-dark');
                        else if (btn.dataset.status === 'rejected')
                            btn.classList.add('border-chip-rejected', 'text-chip-rejected');
                        else
                            btn.classList.add('border-gray-400', 'text-gray-500');
                    }
                }
            }

            function applyFilter() {
                state.filtered = state.data.filter(function (item) {
                    var matchStatus = state.filter === 'all' || item.status === state.filter;
                    var matchSearch = !state.search ||
                            item.pet.toLowerCase().indexOf(state.search) !== -1 ||
                            item.adopter.toLowerCase().indexOf(state.search) !== -1 ||
                            item.breed.toLowerCase().indexOf(state.search) !== -1;
                    return matchStatus && matchSearch;
                });
                updateCounts();
                renderTable(); // Ganti ini
                updatePaginationButtons(); // Tambah function baru
            }

            function updatePaginationButtons() {
                var totalPages = Math.ceil(state.filtered.length / state.perPage);
                var prevBtn = document.getElementById('prev-btn');
                var nextBtn = document.getElementById('next-btn');

                prevBtn.disabled = state.page <= 1;
                nextBtn.disabled = state.page >= totalPages;
            }

            function updateCounts() {
                var pendingCount = state.data.filter(function (i) {
                    return i.status === 'pending';
                }).length;
                els.counts.displayPending.innerText = pendingCount;
                document.getElementById('total-items').innerText = state.filtered.length;
            }

            function renderTable() {
                var displayData = state.filtered;
                var start = (state.page - 1) * state.perPage;
                var end = Math.min(start + state.perPage, displayData.length);
                var pageData = displayData.slice(start, end);

                // Update pagination info
                document.getElementById('start-index').innerText = displayData.length > 0 ? start + 1 : 0;
                document.getElementById('end-index').innerText = end;
                document.getElementById('total-items').innerText = displayData.length;

                // Enable/disable pagination buttons
                document.getElementById('prev-btn').disabled = state.page <= 1;
                document.getElementById('next-btn').disabled = end >= displayData.length;

                if (pageData.length === 0) {
                    els.table.innerHTML = '<tr><td colspan="6" class="px-6 py-12 text-center text-gray-500">No requests found.</td></tr>';
                    return;
                }

                var tableHTML = '';
                for (var i = 0; i < pageData.length; i++) {
                    var item = pageData[i];
                    var statusBadge = getStatusBadge(item.status);

                    // Button style
                    var btnHtml = getActionButton(item);

                    tableHTML +=
                            '<tr class="hover:bg-gray-50 transition">' +
                            '<td class="px-6 py-4 text-sm font-medium text-gray-400">#' + item.id + '</td>' +
                            '<td class="px-6 py-4">' +
                            '<div class="flex items-center gap-3">' +
                            '<img class="h-10 w-10 rounded-lg object-cover bg-gray-100" src="' + item.pet_img + '" onerror="this.src=\'default_pet.jpg\'">' +
                            '<div>' +
                            '<div class="text-sm font-bold text-text-main">' + item.pet + '</div>' +
                            '<div class="text-xs text-gray-500">' + item.breed + '</div>' +
                            '</div>' +
                            '</div>' +
                            '</td>' +
                            '<td class="px-6 py-4">' +
                            '<div class="flex items-center gap-3">' +
                            '<img class="h-8 w-8 rounded-full object-cover border border-divider" src="' + item.adopter_img + '" onerror="this.src=\'default_user.jpg\'">' +
                            '<div class="text-sm font-medium">' + item.adopter + '</div>' +
                            '</div>' +
                            '</td>' +
                            '<td class="px-6 py-4 text-sm text-gray-500">' + formatDate(item.date) + '</td>' +
                            '<td class="px-6 py-4">' + statusBadge + '</td>' +
                            '<td class="px-6 py-4 text-center">' + btnHtml + '</td>' +
                            '</tr>';
                }

                els.table.innerHTML = tableHTML;
            }

            function getStatusBadge(status) {
                var badgeClass = '';
                var text = status.charAt(0).toUpperCase() + status.slice(1);

                switch (status) {
                    case 'pending':
                        badgeClass = 'bg-chip-pending text-white';
                        break;
                    case 'approved':
                        badgeClass = 'bg-chip-approved text-primary-dark';
                        break;
                    case 'rejected':
                        badgeClass = 'bg-chip-rejected text-white';
                        break;
                    case 'cancelled':
                        badgeClass = 'bg-gray-200 text-gray-600';
                        break;
                    default:
                        badgeClass = 'bg-gray-100 text-gray-700';
                }

                return '<span class="px-3 py-1 rounded-full text-xs font-bold ' + badgeClass + '">' + text + '</span>';
            }

// Helper function untuk action button
            function getActionButton(item) {
                if (item.status === 'pending') {
                    return '<button onclick="openReviewModal(' + item.id + ')" class="px-4 py-2 rounded-lg bg-primary text-white text-xs font-bold uppercase tracking-wide hover:bg-primary-dark transition shadow-md hover:shadow-lg">Review</button>';
                } else {
                    return '<button onclick="openReviewModal(' + item.id + ')" class="px-4 py-2 rounded-lg bg-white border border-gray-300 text-gray-600 text-xs font-bold uppercase tracking-wide hover:bg-gray-50 transition shadow-sm">View</button>';
                }
            }

            function formatDate(dateStr) {
                if (!dateStr)
                    return '';
                var date = new Date(dateStr);
                if (isNaN(date.getTime()))
                    return dateStr;
                return date.toISOString().split('T')[0];
            }

            // --- MODAL LOGIC ---

            // TAMBAH di function openReviewModal():
            function openReviewModal(id) {
                console.log('Opening modal for request ID:', id); // Debug

                var item = null;
                for (var i = 0; i < state.data.length; i++) {
                    if (state.data[i].id === id) {
                        item = state.data[i];
                        console.log('Found item:', item); // Debug
                        break;
                    }
                }
                if (!item) {
                    console.error('Item not found for ID:', id);
                    return;
                }
                state.currentId = id;

                setModalContent(item);
                document.getElementById('reviewModal').classList.add('active');
            }

            function setModalContent(item) {
                function set(id, val) {
                    document.getElementById(id).innerText = val || '-';
                }

                // Basic Info
                set('review-request-id', item.id);
                document.getElementById('review-pet-photo').src = item.pet_img;
                document.getElementById('review-pet-photo').onerror = function () {
                    this.src = 'default_pet.jpg';
                };
                set('review-pet-name', item.pet);
                set('review-pet-breed', item.breed + ' (' + item.species + ')');
                set('review-pet-gender', item.gender);
                set('review-pet-age', item.age);
                set('review-pet-health', item.health);

                // Adopter Info
                document.getElementById('review-adopter-photo').src = item.adopter_img;
                document.getElementById('review-adopter-photo').onerror = function () {
                    this.src = 'default_user.jpg';
                };
                set('review-adopter-name', item.adopter);
                set('review-adopter-occupation', item.job);
                set('review-adopter-email', item.adopter_email || item.adopter.replace(/\s+/g, '.').toLowerCase() + "@email.com");
                set('review-adopter-message', item.msg);

                // Environment
                set('review-adopter-house', item.house ? item.house.replace('_', ' ') : 'Not specified');

                var petEl = document.getElementById('review-adopter-pets');
                if (item.pets) {
                    petEl.innerText = "Yes, has pets";
                    petEl.className = "font-bold text-yellow-600";
                } else {
                    petEl.innerText = "No other pets";
                    petEl.className = "font-bold text-green-600";
                }

                set('review-adopter-notes', item.notes || "No specific notes.");

                // Timeline
                var dateObj = new Date(item.date);
                set('review-request-date', dateObj.toLocaleDateString('en-GB', {day: 'numeric', month: 'long', year: 'numeric'}));
                set('review-request-time', dateObj.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit'}));

                // Status Badge
                var statusBadge = document.getElementById('review-status-badge');
                var statusDot = document.getElementById('review-status-dot');
                statusBadge.innerText = item.status.toUpperCase();

                // Reset classes
                statusBadge.className = "inline-block mt-1 px-2 py-0.5 rounded text-xs font-bold text-white";

                if (item.status === 'pending') {
                    statusBadge.classList.add('bg-chip-pending');
                    statusDot.className = "absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-chip-pending border-2 border-white shadow-sm";
                } else if (item.status === 'approved') {
                    statusBadge.classList.add('bg-chip-approved', '!text-primary-dark');
                    statusDot.className = "absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-secondary border-2 border-white shadow-sm";
                } else if (item.status === 'rejected') {
                    statusBadge.classList.add('bg-chip-rejected');
                    statusDot.className = "absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-chip-rejected border-2 border-white shadow-sm";
                } else {
                    statusBadge.classList.add('bg-gray-400');
                    statusDot.className = "absolute -left-[21px] top-1.5 w-3 h-3 rounded-full bg-gray-400 border-2 border-white shadow-sm";
                }

                // Cancellation Logic
                var cancelBlock = document.getElementById('cancellation-block');
                if (item.status === 'cancelled' && item.cancellation_reason) {
                    cancelBlock.classList.remove('hidden');
                    document.getElementById('review-cancellation-reason').innerText = item.cancellation_reason;
                } else {
                    cancelBlock.classList.add('hidden');
                }

                // Toggle Input vs Readonly
                var actionSec = document.getElementById('action-section');
                var footerSec = document.getElementById('readonly-footer');
                var responseBox = document.getElementById('shelter-response');

                responseBox.value = item.response || "";

                if (item.status === 'pending') {
                    actionSec.classList.remove('hidden');
                    footerSec.classList.add('hidden');
                } else {
                    actionSec.classList.add('hidden');
                    footerSec.classList.remove('hidden');
                    document.getElementById('readonly-response-text').innerText = item.response || "No response recorded.";
                }
            }

            function closeModal(id) {
                document.getElementById(id).classList.remove('active');
            }

            // --- CONFIRMATION LOGIC ---

            function promptConfirmation(type) {
                var responseVal = document.getElementById('shelter-response').value.trim();
                if (!responseVal) {
                    showToast('Action Failed', 'Please write a response message first.', 'error');
                    document.getElementById('shelter-response').focus();
                    return;
                }
                state.pendingAction = type;

                var title = document.getElementById('confirm-title');
                var iconContainer = document.getElementById('confirm-icon-container');
                var icon = document.getElementById('confirm-icon');
                var confirmBtn = document.getElementById('confirm-yes-btn');

                if (type === 'approve') {
                    title.innerText = "Approve Application?";
                    iconContainer.className = "w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 bg-secondary";
                    icon.className = "fas fa-check text-3xl text-primary-dark";
                    confirmBtn.className = "flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90 bg-primary";
                } else {
                    title.innerText = "Reject Application?";
                    iconContainer.className = "w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 bg-chip-rejected";
                    icon.className = "fas fa-times text-3xl text-white";
                    confirmBtn.className = "flex-1 py-2.5 rounded-xl text-white font-bold shadow-md transition hover:opacity-90 bg-chip-rejected";
                }
                confirmBtn.onclick = executeAction;
                document.getElementById('confirmationModal').classList.add('active');
            }

            // GANTI function executeAction() dengan ini:
            // GANTI function executeAction() dengan versi yang lebih detail:
            // GANTI function executeAction() dengan versi yang lebih detail:
            function executeAction() {
                var responseVal = document.getElementById('shelter-response').value.trim();
                var requestId = state.currentId;
                var action = state.pendingAction;

                console.log('=== AJAX REQUEST DETAILS ===');
                console.log('Request ID:', requestId);
                console.log('Action:', action);
                console.log('Response length:', responseVal.length);

                // Validasi lebih ketat
                if (!responseVal) {
                    showToast('Action Failed', 'Please write a response message first.', 'error');
                    document.getElementById('shelter-response').focus();
                    return;
                }

                if (!requestId || isNaN(requestId)) {
                    showToast('Error', 'Invalid request ID.', 'error');
                    return;
                }

                // Create form data dengan encoding yang betul
                var formData = new FormData();
                formData.append('action', action);
                formData.append('requestId', requestId.toString());
                formData.append('response', responseVal);

                // Tambah CSRF token jika ada
                var csrfToken = document.querySelector('meta[name="csrf-token"]');
                if (csrfToken) {
                    formData.append('csrfToken', csrfToken.getAttribute('content'));
                }

                // Debug: Tunjukkan apa yang dihantar
                console.log('FormData contents:');
                for (var pair of formData.entries()) {
                    console.log(pair[0] + ': ' + pair[1]);
                }

                // Show loading
                var confirmBtn = document.getElementById('confirm-yes-btn');
                var originalText = confirmBtn.innerHTML;
                confirmBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Processing...';
                confirmBtn.disabled = true;

                // Make AJAX call dengan timeout
                var xhr = new XMLHttpRequest();
                xhr.open('POST', 'manageAdoptionServlet', true);
                xhr.timeout = 30000; // 30 seconds timeout

                // Set headers
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

                xhr.onload = function () {
                    // Reset button
                    confirmBtn.innerHTML = originalText;
                    confirmBtn.disabled = false;

                    console.log('=== AJAX RESPONSE ===');
                    console.log('Status:', xhr.status);
                    console.log('Response:', xhr.responseText);

                    if (xhr.status === 200) {
                        var response = xhr.responseText.trim();

                        if (response.startsWith('SUCCESS:')) {
                            var parts = response.split(':');
                            var newStatus = parts[1];
                            var updatedId = parseInt(parts[2]);

                            // Update local state
                            var updated = false;
                            for (var i = 0; i < state.data.length; i++) {
                                if (state.data[i].id == updatedId) {
                                    state.data[i].status = newStatus;
                                    state.data[i].response = responseVal;
                                    updated = true;
                                    break;
                                }
                            }

                            closeModal('confirmationModal');
                            closeModal('reviewModal');

                            if (updated) {
                                applyFilter();
                                showToast(
                                        newStatus === 'approved' ? 'Request Approved' : 'Request Rejected',
                                        'Application #' + updatedId + ' has been ' + newStatus + '.',
                                        newStatus === 'approved' ? 'success' : 'error'
                                        );
                            }

                        } else if (response.startsWith('ERROR:')) {
                            var errorMsg = response.substring(6);
                            showToast('Action Failed', errorMsg, 'error');
                            closeModal('confirmationModal');
                        } else {
                            // Response format tidak dijangka
                            console.error('Unexpected response:', response);
                            showToast('Server Error', 'Unexpected response format. Please try again.', 'error');
                            closeModal('confirmationModal');
                        }
                    } else if (xhr.status === 400) {
                        showToast('Bad Request', 'Invalid request parameters. Please refresh and try again.', 'error');
                        closeModal('confirmationModal');
                    } else if (xhr.status === 403) {
                        showToast('Access Denied', 'Your session may have expired. Please login again.', 'error');
                        setTimeout(function () {
                            window.location.href = 'index.jsp';
                        }, 2000);
                    } else if (xhr.status === 500) {
                        showToast('Server Error', 'Internal server error. Please try again later.', 'error');
                        closeModal('confirmationModal');
                    } else {
                        showToast('Error', 'Unexpected error: ' + xhr.status, 'error');
                        closeModal('confirmationModal');
                    }
                };

                xhr.ontimeout = function () {
                    confirmBtn.innerHTML = originalText;
                    confirmBtn.disabled = false;
                    showToast('Timeout', 'Request took too long. Please try again.', 'error');
                    closeModal('confirmationModal');
                };

                xhr.onerror = function () {
                    confirmBtn.innerHTML = originalText;
                    confirmBtn.disabled = false;
                    showToast('Connection Error', 'Failed to connect to server. Check your network.', 'error');
                    closeModal('confirmationModal');
                };

                // Debug: Check what's being sent
                console.log('=== AJAX REQUEST DETAILS ===');
                console.log('Request ID:', requestId);
                console.log('Action:', action);
                console.log('Response length:', responseVal.length);

// Log all form data entries
                for (var pair of formData.entries()) {
                    console.log(pair[0] + ': ' + pair[1]);
                }

                xhr.send(formData);
            }

            // GANTI function showToast():
            function showToast(title, msg, type) {
                var toast = document.getElementById('toast');
                var bg = document.getElementById('toast-bg');
                var icon = document.getElementById('toast-icon');

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
                setTimeout(function () {
                    toast.classList.remove('translate-x-0', 'opacity-100');
                    toast.classList.add('translate-x-full', 'opacity-0');
                }, 4000);
            }

            document.addEventListener('DOMContentLoaded', function () {
                console.log('Page loaded, initializing...');
                console.log('Total requests loaded:', REQUESTS.length);
                init();
            });

// Tambah error handling untuk data loading
            if (REQUESTS.length === 0) {
                console.warn('No request data loaded from server');
                // Optional: Show message to user
                setTimeout(function () {
                    if (document.body && document.querySelector('#requests-table')) {
                        document.querySelector('#requests-table').innerHTML =
                                '<tr><td colspan="6" class="px-6 py-12 text-center text-gray-500">No adoption requests found.</td></tr>';
                    }
                }, 100);
            }
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