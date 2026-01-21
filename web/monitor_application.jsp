<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.model.AdoptionRequest" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>

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

    int adopterId = SessionUtil.getUserId(session);
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Monitor Applications - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">

        <style>
            /* Custom utility classes based on your theme */
            .text-main { color: #2B2B2B; }
            .bg-primary { background-color: #2F5D50; }
            .hover-bg-primary-dark { background-color: #24483E; }
            .text-white-on-dark { color: #FFFFFF; }
            .border-divider { border-color: #E5E5E5; }

            /* Status Chip Styles */
            .chip-pending { background-color: #C49A6C; color: #FFFFFF; } /* Warm Chip */
            .chip-approved { background-color: #A8E6CF; color: #2B2B2B; } /* Light Green Chip */
            .chip-rejected { background-color: #B84A4A; color: #FFFFFF; } /* Danger Alert */
            .chip-cancelled { background-color: #C49A6C; color: #FFFFFF; } /* Warm Chip */

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
        </style>

    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7] text-main">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start" style="background-color: #F6F3E7;">
            <div class="w-full bg-white py-8 px-6 rounded-3xl shadow-xl border" style="max-width: 1450px; border-color: #E5E5E5;">

                <div class="mb-8">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Monitor Applications</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">Check the status of your pet adoption applications here.</p>
                </div>

                <hr style="border-top: 1px solid #E5E5E5; margin-bottom: 1.5rem; margin-top: 1.5rem;" />

                <div class="flex flex-col md:flex-row justify-between items-center mb-6 space-y-4 md:space-y-0">
                    <div class="flex flex-wrap gap-2 text-sm font-medium" id="filter-container">
                        <!-- Filter buttons will be populated by JavaScript -->
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary" data-status="all">All (0)</button>
                        <button class="px-5 py-2 rounded-full border border-[#C49A6C] text-[#C49A6C] hover:bg-[#F6F3E7] transition duration-150 filter-btn" data-status="pending">Pending (0)</button>
                        <button class="px-5 py-2 rounded-full border border-[#6DBF89] text-[#57A677] hover:bg-[#F6F3E7] transition duration-150 filter-btn" data-status="approved">Approved (0)</button>
                        <button class="px-5 py-2 rounded-full border border-[#B84A4A] text-[#B84A4A] hover:bg-[#F6F3E7] transition duration-150 filter-btn" data-status="rejected">Rejected (0)</button>
                        <button class="px-5 py-2 rounded-full border border-[#C49A6C] text-[#C49A6C] hover:bg-[#F6F3E7] transition duration-150 filter-btn" data-status="cancelled">Cancelled (0)</button>
                    </div>

                    <div class="relative w-full md:w-80">
                        <input type="text" id="search-input" placeholder="Search Pet/Shelter..." class="w-full py-2.5 pl-10 pr-4 border rounded-xl transition duration-150 shadow-sm text-base custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                        <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    </div>
                </div>

                <div class="overflow-x-auto rounded-xl border shadow-lg" style="border-color: #E5E5E5;">
                    <table class="min-w-full divide-y" style="border-color: #E5E5E5;">
                        <thead style="background-color: #F6F3E7;">
                            <tr>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 5%;">No.</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Pet</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Shelter</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Date</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Status</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Shelter Response</th>
                                <th class="px-6 py-4 text-center text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 15%;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="application-list" class="bg-white divide-y" style="border-color: #E5E5E5;">
                            <!-- Data will be loaded via AJAX -->
                        </tbody>
                    </table>
                </div>

                <div id="no-data-message" class="hidden text-center py-8">
                    <i class="fas fa-inbox text-5xl text-gray-300 mb-4"></i>
                    <p class="text-lg text-gray-500">No adoption applications found.</p>
                </div>

                <div id="pagination-controls" class="flex justify-between items-center mt-6 hidden">
                    <div class="text-sm" style="color: #2B2B2B;">
                        Showing <span id="start-index" class="font-semibold">1</span> to <span id="end-index" class="font-semibold">10</span> of <span id="total-items" class="font-semibold">0</span> applications
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

        <!-- View Details Modal -->
        <div id="editModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-2xl mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">

                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #2F5D50;">Application Details</h3>
                    <button onclick="closeModal('editModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <div class="max-h-[70vh] overflow-y-auto pr-2">
                    <form id="editForm" class="space-y-4">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Pet:</label>
                                <p class="font-semibold" id="modalPetName" style="color: #2B2B2B;"></p>
                            </div>
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Shelter:</label>
                                <p class="font-semibold" id="modalShelterName" style="color: #2B2B2B;"></p>
                            </div>
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Application Date:</label>
                                <p class="font-semibold" id="modalRequestDate" style="color: #2B2B2B;"></p>
                            </div>
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Status:</label>
                                <p class="font-semibold"><span id="modalStatus" class="px-2 py-1 rounded-full text-xs"></span></p>
                            </div>
                        </div>

                        <h4 class="font-bold pt-2 border-t text-lg" style="border-color: #E5E5E5; color: #2F5D50;">Your Application Details</h4>

                        <div>
                            <label for="modalAdopterMessage" class="block text-sm font-medium" style="color: #2B2B2B;">Message to Shelter:</label>
                            <textarea id="modalAdopterMessage" rows="3" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" readonly></textarea>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium" style="color: #2B2B2B;">Household Type:</label>
                                <p class="font-semibold" id="modalHouseholdType" style="color: #2B2B2B;"></p>
                            </div>
                            <div class="flex items-center">
                                <input id="modalHasOtherPets" type="checkbox" class="h-4 w-4 rounded custom-focus" style="color: #2F5D50; border-color: #E5E5E5;" disabled>
                                <label for="modalHasOtherPets" class="ml-2 block text-sm" style="color: #2B2B2B;">I currently have other pets.</label>
                            </div>
                        </div>

                        <div>
                            <label for="modalAdopterNotes" class="block text-sm font-medium" style="color: #2B2B2B;">General Notes:</label>
                            <textarea id="modalAdopterNotes" rows="2" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" readonly></textarea>
                        </div>

                        <h4 class="font-bold pt-2 border-t text-lg" style="border-color: #E5E5E5; color: #2F5D50;">Shelter Feedback</h4>
                        <div class="p-3 rounded-lg border" style="background-color: #F6F3E7; border-color: #E5E5E5;">
                            <p class="text-sm italic text-gray-600" id="modalShelterResponse">No response yet</p>
                        </div>

                        <div id="cancellationReasonSection" class="hidden">
                            <h4 class="font-bold pt-2 border-t text-lg" style="border-color: #E5E5E5; color: #B84A4A;">Cancellation Reason</h4>
                            <div class="p-3 rounded-lg border" style="background-color: #FFE5E5; border-color: #B84A4A;">
                                <p class="text-sm italic text-gray-600" id="modalCancellationReason"></p>
                            </div>
                        </div>
                    </form>
                </div>

                <div class="flex justify-end pt-4">
                    <button type="button" onclick="closeModal('editModal')" class="px-6 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Close
                    </button>
                </div>

            </div>
        </div>

        <!-- Cancel Confirmation Modal -->
        <div id="cancelModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-md mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">

                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #B84A4A;">Confirm Cancellation</h3>
                    <button onclick="closeModal('cancelModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <div class="text-gray-700">
                    <p class="mb-4 text-lg" style="color: #2B2B2B;">Are you sure you want to cancel your application for <strong id="cancelPetName" style="color: #2B2B2B;"></strong> from <strong id="cancelShelterName" style="color: #2B2B2B;"></strong>?</p>
                    <p class="mb-6 text-sm italic text-white font-medium p-3 rounded-lg border" style="background-color: #B84A4A; border-color: #B84A4A;">
                        This action cannot be undone. Once cancelled, you will need to submit a new application.
                    </p>

                    <div>
                        <label for="cancellationReason" class="block text-sm font-medium" style="color: #2B2B2B;">Reason for Cancellation (Optional):</label>
                        <textarea id="cancellationReason" rows="2" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;"></textarea>
                    </div>
                </div>

                <div class="flex justify-end space-x-3 pt-4">
                    <button onclick="closeModal('cancelModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Go Back
                    </button>
                    <button id="confirmCancelBtn" class="px-5 py-2 rounded-xl text-white font-semibold hover:bg-red-700 transition duration-200 shadow-md" style="background-color: #B84A4A;">
                        Yes, Cancel Application
                    </button>
                </div>

            </div>
        </div>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <script src="includes/sidebar.js"></script>

        <script>
                        // =======================================================
                        // 1. Global Variables
                        // =======================================================
                        var ITEMS_PER_PAGE = 10;
                        var currentPage = 1;
                        var filteredData = [];
                        var currentStatusFilter = 'all';
                        var currentApplicationId = null;
                        var allApplications = [];

                        // =======================================================
                        // 2. MODAL FUNCTIONS - FIXED
                        // =======================================================
                        function openModal(modalId, appId) {
                            console.log('Opening modal:', modalId, 'for app ID:', appId);

                            var modal = document.getElementById(modalId);
                            var application = null;

                            // Find application by ID
                            for (var i = 0; i < allApplications.length; i++) {
                                if (allApplications[i].request_id == appId) {
                                    application = allApplications[i];
                                    console.log('Found application:', application);
                                    break;
                                }
                            }

                            if (!application) {
                                console.error('Application not found for ID:', appId);
                                return;
                            }

                            currentApplicationId = appId;

                            if (modalId === 'editModal') {
                                // Populate View Details modal
                                document.getElementById('modalPetName').textContent = application.pet_name || 'Unknown Pet';
                                document.getElementById('modalShelterName').textContent = application.shelter_name || 'Unknown Shelter';
                                document.getElementById('modalRequestDate').textContent = formatDate(application.request_date);
                                document.getElementById('modalAdopterMessage').value = application.adopter_message || '';
                                document.getElementById('modalHouseholdType').textContent = application.household_type || 'Not specified';
                                document.getElementById('modalHasOtherPets').checked = application.has_other_pets === 1 || application.has_other_pets === true;
                                document.getElementById('modalAdopterNotes').value = application.notes || '';
                                document.getElementById('modalShelterResponse').textContent = application.shelter_response || 'No response yet';
                                document.getElementById('modalCancellationReason').textContent = application.cancellation_reason || '';

                                // Set status with appropriate styling
                                var statusElement = document.getElementById('modalStatus');
                                statusElement.textContent = application.status ? application.status.charAt(0).toUpperCase() + application.status.slice(1) : 'Unknown';
                                statusElement.className = 'px-2 py-1 rounded-full text-xs ' + getStatusChipClass(application.status);

                                // Show/hide cancellation reason section
                                var cancellationSection = document.getElementById('cancellationReasonSection');
                                if (application.cancellation_reason) {
                                    cancellationSection.classList.remove('hidden');
                                } else {
                                    cancellationSection.classList.add('hidden');
                                }

                            } else if (modalId === 'cancelModal') {
                                // Populate Cancel modal
                                document.getElementById('cancelPetName').textContent = application.pet_name || 'Pet';
                                document.getElementById('cancelShelterName').textContent = application.shelter_name || 'Shelter';

                                // Set up confirmation button
                                var confirmBtn = document.getElementById('confirmCancelBtn');
                                confirmBtn.onclick = function () {
                                    confirmCancellation(application.request_id);
                                };
                            }

                            // Show modal with animation
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
                                if (modalId === 'cancelModal') {
                                    document.getElementById('cancellationReason').value = '';
                                }
                            }, 300);
                        }

                        function confirmCancellation(appId) {
                            var reason = document.getElementById('cancellationReason').value;

                            console.log('DEBUG: Cancelling application ID:', appId);
                            console.log('DEBUG: Reason:', reason);

                            // FIX: Use URL encoded parameters
                            var params = new URLSearchParams();
                            params.append('action', 'cancelAdopterRequest');
                            params.append('requestId', appId);
                            params.append('cancellationReason', reason);

                            // FIX: Send with proper headers
                            fetch('ManageAdoptionRequest', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/x-www-form-urlencoded',
                                },
                                body: params.toString()
                            })
                                    .then(response => {
                                        console.log('DEBUG: Response status:', response.status);
                                        if (!response.ok) {
                                            throw new Error('Network response was not ok: ' + response.status);
                                        }
                                        return response.json();
                                    })
                                    .then(data => {
                                        console.log('DEBUG: Server response:', data);
                                        if (data.success) {
                                            alert('Application cancelled successfully!');
                                            closeModal('cancelModal');
                                            loadApplications(); // Reload data
                                        } else {
                                            alert('Failed to cancel application: ' + (data.message || 'Unknown error'));
                                        }
                                    })
                                    .catch(error => {
                                        console.error('Error:', error);
                                        alert('Error cancelling application. Please try again.');
                                    });
                        }

                        // =======================================================
                        // 3. Data Loading Functions
                        // =======================================================
                        function loadApplications() {
                            console.log('Loading applications for adopter ID:', <%= adopterId%>);

                            // FIX: Remove adopterId parameter since it's already in session
                            fetch('ManageAdoptionRequest?action=getAdopterApplications')
                                    .then(response => {
                                        if (!response.ok) {
                                            throw new Error('Network response was not ok: ' + response.status);
                                        }
                                        return response.json();
                                    })
                                    .then(data => {
                                        console.log('Applications loaded:', data);
                                        allApplications = data;
                                        filterAndRender();
                                        updateFilterButtonCounts();
                                    })
                                    .catch(error => {
                                        console.error('Error loading applications:', error);
                                        showNoDataMessage();
                                        alert('Failed to load applications. Please refresh the page.');
                                    });
                        }

                        function getStatusChipClass(status) {
                            switch (status) {
                                case 'pending':
                                    return 'chip-pending';
                                case 'approved':
                                    return 'chip-approved';
                                case 'rejected':
                                    return 'chip-rejected';
                                case 'cancelled':
                                    return 'chip-cancelled';
                                default:
                                    return 'bg-gray-200 text-gray-800';
                            }
                        }

                        function formatDate(dateString) {
                            if (!dateString)
                                return '';
                            try {
                                var date = new Date(dateString);
                                return date.toLocaleDateString('en-GB', {
                                    day: '2-digit',
                                    month: '2-digit',
                                    year: 'numeric'
                                });
                            } catch (e) {
                                console.error('Error formatting date:', dateString, e);
                                return dateString;
                            }
                        }

                        function renderTable(data, page) {
                            var tableBody = document.getElementById('application-list');
                            var noDataMessage = document.getElementById('no-data-message');
                            var paginationControls = document.getElementById('pagination-controls');

                            if (data.length === 0) {
                                tableBody.innerHTML = '';
                                noDataMessage.classList.remove('hidden');
                                paginationControls.classList.add('hidden');
                                return;
                            }

                            noDataMessage.classList.add('hidden');
                            paginationControls.classList.remove('hidden');

                            tableBody.innerHTML = '';

                            var start = (page - 1) * ITEMS_PER_PAGE;
                            var end = start + ITEMS_PER_PAGE;
                            var paginatedItems = data.slice(start, end);

                            for (var i = 0; i < paginatedItems.length; i++) {
                                var item = paginatedItems[i];
                                var statusChipClass = getStatusChipClass(item.status);
                                var itemNumber = start + i + 1;

                                // Action Buttons
                                var actionButtons;
                                if (item.status === 'pending') {
                                    actionButtons = '<div class="flex flex-col items-center space-y-2">' +
                                            '<button onclick="openModal(\'editModal\', ' + item.request_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View Details</button>' +
                                            '<button onclick="openModal(\'cancelModal\', ' + item.request_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-red-700" style="background-color: #B84A4A;">Cancel</button>' +
                                            '</div>';
                                } else {
                                    actionButtons = '<button onclick="openModal(\'editModal\', ' + item.request_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View Details</button>';
                                }

                                var row = '<tr class="hover:bg-gray-50 transition duration-100">' +
                                        '<td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;">' + itemNumber + '</td>' +
                                        '<td class="px-6 py-4 whitespace-nowrap">' +
                                        '<div class="flex items-center">' +
                                        '<div class="flex-shrink-0 h-10 w-10">' +
                                        '<img class="h-10 w-10 rounded-full object-cover" src="' + (item.pet_photo || 'https://via.placeholder.com/40x40?text=Pet') + '" alt="' + (item.pet_name || 'Pet') + '" onerror="this.src=\'https://via.placeholder.com/40x40?text=Pet\'">' +
                                        '</div>' +
                                        '<div class="ml-4">' +
                                        '<div class="text-sm font-medium" style="color: #2B2B2B;">' + (item.pet_name || 'Unknown Pet') + '</div>' +
                                        '</div>' +
                                        '</div>' +
                                        '</td>' +
                                        '<td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">' + (item.shelter_name || 'Unknown Shelter') + '</td>' +
                                        '<td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">' + formatDate(item.request_date) + '</td>' +
                                        '<td class="px-6 py-4 whitespace-nowrap">' +
                                        '<span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full text-white ' + statusChipClass + '">' +
                                        (item.status ? item.status.charAt(0).toUpperCase() + item.status.slice(1) : 'Unknown') +
                                        '</span>' +
                                        '</td>' +
                                        '<td class="px-6 py-4 text-sm truncate max-w-xs" style="color: #2B2B2B;" title="' + (item.shelter_response || 'No response yet') + '">' +
                                        (item.shelter_response || 'No response yet') +
                                        '</td>' +
                                        '<td class="px-6 py-4 whitespace-nowrap text-center">' +
                                        actionButtons +
                                        '</td>' +
                                        '</tr>';

                                tableBody.innerHTML += row;
                            }

                            renderPaginationControls(data.length);
                        }

                        function renderPaginationControls(totalItems) {
                            var totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);

                            document.getElementById('total-items').textContent = totalItems;
                            document.getElementById('start-index').textContent = Math.min(totalItems, (currentPage - 1) * ITEMS_PER_PAGE + 1);
                            document.getElementById('end-index').textContent = Math.min(totalItems, currentPage * ITEMS_PER_PAGE);

                            document.getElementById('prev-btn').disabled = currentPage === 1;
                            document.getElementById('next-btn').disabled = currentPage === totalPages || totalItems === 0;
                        }

                        // =======================================================
                        // 4. Filtering and Search Functions
                        // =======================================================
                        function filterAndRender() {
                            // Apply filter based on currentStatusFilter
                            if (currentStatusFilter === 'all') {
                                filteredData = allApplications;
                            } else {
                                filteredData = allApplications.filter(function (app) {
                                    return app.status === currentStatusFilter;
                                });
                            }

                            currentPage = 1;
                            renderTable(filteredData, currentPage);
                        }

                        function updateFilterButtonCounts() {
                            var counts = {
                                'all': allApplications.length,
                                'pending': 0,
                                'approved': 0,
                                'rejected': 0,
                                'cancelled': 0
                            };

                            // Count each status
                            allApplications.forEach(function (app) {
                                if (counts[app.status] !== undefined) {
                                    counts[app.status]++;
                                }
                            });

                            var filterButtons = document.querySelectorAll('.filter-btn');
                            filterButtons.forEach(function (btn) {
                                var status = btn.getAttribute('data-status');
                                var count = counts[status] || 0;

                                // Update button text while preserving the label
                                var btnText = btn.textContent || btn.innerText;
                                var baseText = btnText.replace(/\(\d+\)/, '').trim();
                                btn.textContent = baseText + ' (' + count + ')';
                            });
                        }

                        function updateFilterButtonStyles() {
                            var filterButtons = document.querySelectorAll('.filter-btn');

                            filterButtons.forEach(function (btn) {
                                var btnStatus = btn.getAttribute('data-status');

                                // Reset semua classes
                                btn.className = 'px-5 py-2 rounded-full text-sm font-medium transition duration-150 filter-btn';

                                // Set active button
                                if (btnStatus === currentStatusFilter) {
                                    if (btnStatus === 'all') {
                                        btn.classList.add('bg-primary', 'text-white', 'shadow-md');
                                    } else if (btnStatus === 'pending' || btnStatus === 'cancelled') {
                                        btn.classList.add('bg-[#C49A6C]', 'text-white', 'border-[#C49A6C]');
                                    } else if (btnStatus === 'approved') {
                                        btn.classList.add('bg-[#A8E6CF]', 'text-[#06321F]', 'border-[#6DBF89]');
                                    } else if (btnStatus === 'rejected') {
                                        btn.classList.add('bg-[#B84A4A]', 'text-white', 'border-[#B84A4A]');
                                    }
                                } else {
                                    // Inactive button styles
                                    btn.classList.add('border', 'hover:bg-[#F6F3E7]');
                                    if (btnStatus === 'all') {
                                        btn.classList.add('border-[#2F5D50]', 'text-[#2F5D50]');
                                    } else if (btnStatus === 'pending' || btnStatus === 'cancelled') {
                                        btn.classList.add('border-[#C49A6C]', 'text-[#C49A6C]');
                                    } else if (btnStatus === 'approved') {
                                        btn.classList.add('border-[#6DBF89]', 'text-[#57A677]');
                                    } else if (btnStatus === 'rejected') {
                                        btn.classList.add('border-[#B84A4A]', 'text-[#B84A4A]');
                                    }
                                }
                            });
                        }

                        // =======================================================
                        // 5. Event Listeners and Initialization
                        // =======================================================
                        document.addEventListener('DOMContentLoaded', function () {
                            console.log('DOM loaded, initializing...');

                            // Load applications on page load
                            loadApplications();

                            // Initialize filter buttons
                            document.querySelectorAll('.filter-btn').forEach(function (button) {
                                button.addEventListener('click', function (e) {
                                    currentStatusFilter = e.target.getAttribute('data-status');
                                    updateFilterButtonStyles();
                                    filterAndRender();
                                });
                            });

                            // Pagination buttons
                            document.getElementById('prev-btn').addEventListener('click', function () {
                                if (currentPage > 1) {
                                    currentPage--;
                                    renderTable(filteredData, currentPage);
                                }
                            });

                            document.getElementById('next-btn').addEventListener('click', function () {
                                var totalPages = Math.ceil(filteredData.length / ITEMS_PER_PAGE);
                                if (currentPage < totalPages) {
                                    currentPage++;
                                    renderTable(filteredData, currentPage);
                                }
                            });

                            // Search functionality
                            document.getElementById('search-input').addEventListener('input', function (e) {
                                var searchTerm = e.target.value.toLowerCase();

                                if (searchTerm.trim() === '') {
                                    filterAndRender();
                                    return;
                                }

                                filteredData = allApplications.filter(function (item) {
                                    var petName = (item.pet_name || '').toLowerCase();
                                    var shelterName = (item.shelter_name || '').toLowerCase();
                                    return petName.indexOf(searchTerm) !== -1 ||
                                            shelterName.indexOf(searchTerm) !== -1;
                                });

                                currentPage = 1;
                                renderTable(filteredData, currentPage);
                            });

                            // Initial filter button styling
                            updateFilterButtonStyles();
                        });

                        function showNoDataMessage() {
                            document.getElementById('application-list').innerHTML = '';
                            document.getElementById('no-data-message').classList.remove('hidden');
                            document.getElementById('pagination-controls').classList.add('hidden');
                        }
        </script>
    </body>
</html>