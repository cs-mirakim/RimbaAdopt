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
        <title>Monitor Lost Animals - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
        <style>
            /* Custom utility classes based on your theme */
            .text-main { color: #2B2B2B; }
            .bg-primary { background-color: #2F5D50; }
            .hover-bg-primary-dark { background-color: #24483E; }
            .text-white-on-dark { color: #FFFFFF; }
            .border-divider { border-color: #E5E5E5; }
            /* Status Chip Styles */
            .chip-lost { background-color: #B84A4A; color: #FFFFFF; }
            .chip-found { background-color: #A8E6CF; color: #2B2B2B; }
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
                width: 130px;
                padding: 0.5rem 0;
                text-align: center;
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

            /* File upload styles */
            .file-upload {
                border: 2px dashed #E5E5E5;
                border-radius: 0.5rem;
                padding: 1.5rem;
                text-align: center;
                cursor: pointer;
                transition: all 0.3s ease;
            }

            .file-upload:hover {
                border-color: #2F5D50;
                background-color: #F6F3E7;
            }

            .file-upload.dragover {
                border-color: #2F5D50;
                background-color: #E8F5E8;
            }

            .preview-image {
                max-width: 200px;
                max-height: 200px;
                object-fit: cover;
                border-radius: 0.5rem;
                border: 2px solid #E5E5E5;
            }

            /* Delete confirmation modal */
            .delete-confirmation {
                background-color: #FEF2F2;
                border: 1px solid #FECACA;
                color: #7F1D1D;
                padding: 1rem;
                border-radius: 0.5rem;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7] text-main">
        <jsp:include page="includes/header.jsp" />
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start" style="background-color: #F6F3E7;">
            <div class="w-full bg-white py-8 px-6 rounded-3xl shadow-xl border" style="max-width: 1450px; border-color: #E5E5E5;">
                <div class="mb-8 flex justify-between items-center">
                    <div>
                        <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Monitor Lost Animals</h1>
                        <p class="mt-2 text-lg" style="color: #2B2B2B;">Track and manage your lost pet reports here.</p>
                    </div>
                    <button onclick="openModal('createModal')" class="px-6 py-3 rounded-xl text-white font-semibold hover:bg-[#24483E] transition duration-150 shadow-lg flex items-center space-x-2" style="background-color: #2F5D50;">
                        <i class="fas fa-plus"></i>
                        <span>Report Lost Pet</span>
                    </button>
                </div>

                <!-- Error and Success Messages -->
                <div id="errorMessage" class="hidden error-message"></div>
                <div id="successMessage" class="hidden success-message"></div>

                <hr style="border-top: 1px solid #E5E5E5; margin-bottom: 1.5rem; margin-top: 1.5rem;" />
                <div class="flex flex-col md:flex-row justify-between items-center mb-6 space-y-4 md:space-y-0">
                    <div class="flex flex-wrap gap-2 text-sm font-medium">
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary" data-status="all">All (<span id="countAll">0</span>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#B84A4A] text-[#B84A4A]" data-status="lost">🔴 Lost (<span id="countLost">0</span>)</button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#6DBF89] text-[#57A677]" data-status="found">✅ Found (<span id="countFound">0</span>)</button>
                    </div>
                    <div class="relative w-full md:w-80">
                        <input type="text" id="searchInput" placeholder="Search Pet Name..." class="w-full py-2.5 pl-10 pr-4 border rounded-xl transition duration-150 shadow-sm text-base custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                        <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    </div>
                </div>
                <div class="overflow-x-auto rounded-xl border shadow-lg" style="border-color: #E5E5E5;">
                    <table class="min-w-full divide-y" style="border-color: #E5E5E5;">
                        <thead style="background-color: #F6F3E7;">
                            <tr>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 5%;">No.</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Pet</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Species</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Last Seen Location</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Last Seen Date</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Status</th>
                                <th class="px-6 py-4 text-center text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 20%;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="lost-animal-list" class="bg-white divide-y" style="border-color: #E5E5E5;">
                            <!-- Data akan diisi oleh JavaScript -->
                        </tbody>
                    </table>
                </div>
                <div id="pagination-controls" class="flex justify-between items-center mt-6">
                    <div class="text-sm" style="color: #2B2B2B;">
                        Showing <span id="start-index" class="font-semibold">0</span> to <span id="end-index" class="font-semibold">0</span> of <span id="total-items" class="font-semibold">0</span> reports
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

        <!-- Create/Edit Modal -->
        <div id="createModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-2xl mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #2F5D50;" id="modalTitle">Report Lost Pet</h3>
                    <button onclick="closeModal('createModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="max-h-[70vh] overflow-y-auto pr-2">
                    <form id="reportForm" class="space-y-4" enctype="multipart/form-data">
                        <!-- Hidden input for report ID in edit mode -->
                        <input type="hidden" id="lostId" name="lostId" value="">

                        <!-- Pet Photo Upload -->
                        <div>
                            <label class="block text-sm font-medium" style="color: #2B2B2B;">Pet Photo:</label>
                            <div id="fileUploadArea" class="file-upload mt-1" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)" ondrop="handleDrop(event)">
                                <input type="file" id="petPhoto" name="pet_photo" accept="image/*" class="hidden" onchange="handleFileSelect(event)">
                                <div id="uploadContent">
                                    <i class="fas fa-cloud-upload-alt text-4xl mb-2" style="color: #2F5D50;"></i>
                                    <p class="text-sm" style="color: #2B2B2B;">Drag & drop a photo here or click to browse</p>
                                    <p class="text-xs text-gray-500 mt-1">Recommended: JPG, PNG up to 5MB</p>
                                </div>
                                <div id="previewContainer" class="hidden mt-4">
                                    <img id="imagePreview" class="preview-image mx-auto">
                                    <div class="mt-2">
                                        <button type="button" onclick="removeImage()" class="text-sm text-red-600 hover:text-red-800">
                                            <i class="fas fa-trash mr-1"></i> Remove Image
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <p id="currentImageInfo" class="text-xs text-gray-500 mt-1 hidden">
                                <i class="fas fa-info-circle"></i> Current image will be replaced if you upload a new one.
                            </p>
                        </div>

                        <div>
                            <label for="petName" class="block text-sm font-medium" style="color: #2B2B2B;">Pet Name: <span class="text-red-500">*</span></label>
                            <input type="text" id="petName" name="pet_name" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Enter pet's name">
                        </div>
                        <div>
                            <label for="species" class="block text-sm font-medium" style="color: #2B2B2B;">Species: <span class="text-red-500">*</span></label>
                            <select id="species" name="species" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                                <option value="">Select species</option>
                                <option value="dog">Dog</option>
                                <option value="cat">Cat</option>
                                <option value="rabbit">Rabbit</option>
                                <option value="bird">Bird</option>
                                <option value="other">Other</option>
                            </select>
                        </div>
                        <div>
                            <label for="lastSeenLocation" class="block text-sm font-medium" style="color: #2B2B2B;">Last Seen Location: <span class="text-red-500">*</span></label>
                            <input type="text" id="lastSeenLocation" name="last_seen_location" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="E.g., Near Taman Jaya Park, Petaling Jaya">
                        </div>
                        <div>
                            <label for="lastSeenDate" class="block text-sm font-medium" style="color: #2B2B2B;">Last Seen Date: <span class="text-red-500">*</span></label>
                            <input type="date" id="lastSeenDate" name="last_seen_date" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                        </div>
                        <div>
                            <label for="description" class="block text-sm font-medium" style="color: #2B2B2B;">Description:</label>
                            <textarea id="description" name="description" rows="4" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Describe your pet - color, size, unique markings, temperament, etc."></textarea>
                            <p class="text-xs text-gray-500 mt-1">Provide as much detail as possible to help others identify your pet.</p>
                        </div>
                        <div>
                            <label for="contactInfo" class="block text-sm font-medium" style="color: #2B2B2B;">Your Contact Information: <span class="text-red-500">*</span></label>
                            <textarea id="contactInfo" name="contact_info" rows="3" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Phone number, email, or other contact details..." required></textarea>
                            <p class="text-xs text-gray-500 mt-1">This information will be visible to users who may have found your pet.</p>
                        </div>
                    </form>
                </div>
                <div class="flex justify-end pt-4 space-x-3">
                    <button onclick="closeModal('createModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Cancel
                    </button>
                    <button onclick="saveReport()" id="submitReportBtn" class="px-6 py-2 rounded-xl text-white font-medium hover:bg-[#24483E] transition duration-150 shadow-md" style="background-color: #2F5D50;">
                        Submit Report
                    </button>
                </div>
            </div>
        </div>

        <!-- Mark as Found Modal -->
        <div id="foundModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-md mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #57A677;">Mark as Found</h3>
                    <button onclick="closeModal('foundModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="text-gray-700">
                    <p class="mb-4 text-lg" style="color: #2B2B2B;">Great news! Have you found <strong id="foundPetName" style="color: #2B2B2B;"></strong>?</p>
                    <p class="mb-6 text-sm italic text-white font-medium p-3 rounded-lg border" style="background-color: #A8E6CF; border-color: #6DBF89; color: #2B2B2B;">
                        Once marked as found, this report will be moved to the "Found" section and cannot be edited.
                    </p>
                    <div>
                        <label for="foundNotes" class="block text-sm font-medium" style="color: #2B2B2B;">Additional Notes (Optional):</label>
                        <textarea id="foundNotes" rows="3" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Where/how did you find your pet?"></textarea>
                    </div>
                </div>
                <div class="flex justify-end space-x-3 pt-4">
                    <button onclick="closeModal('foundModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Cancel
                    </button>
                    <button id="confirmFoundBtn" class="px-5 py-2 rounded-xl text-white font-semibold hover:bg-green-700 transition duration-200 shadow-md" style="background-color: #57A677;">
                        Yes, Mark as Found
                    </button>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div id="deleteModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-md mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #B84A4A;">Delete Report</h3>
                    <button onclick="closeModal('deleteModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="delete-confirmation mb-6">
                    <p class="text-lg" style="color: #7F1D1D;">
                        <i class="fas fa-exclamation-triangle mr-2"></i>
                        Are you sure you want to delete this lost pet report?
                    </p>
                    <p class="mt-2 text-sm" style="color: #2B2B2B;">
                        This action cannot be undone. All data including the pet photo will be permanently deleted.
                    </p>
                </div>
                <div class="flex justify-end space-x-3 pt-4">
                    <button onclick="closeModal('deleteModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Cancel
                    </button>
                    <button id="confirmDeleteBtn" class="px-5 py-2 rounded-xl text-white font-semibold hover:bg-red-800 transition duration-200 shadow-md" style="background-color: #B84A4A;">
                        Yes, Delete Report
                    </button>
                </div>
            </div>
        </div>

        <!-- View Details Modal (Read-only for Found pets) -->
        <div id="viewModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-2xl mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #2F5D50;">Pet Details</h3>
                    <button onclick="closeModal('viewModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="max-h-[70vh] overflow-y-auto pr-2">
                    <div class="space-y-4">
                        <div class="p-3 rounded-lg border" style="background-color: #A8E6CF; border-color: #6DBF89;">
                            <p class="text-sm font-semibold" style="color: #2B2B2B;">✅ This pet has been found!</p>
                        </div>

                        <!-- Photo preview -->
                        <div class="text-center">
                            <img id="viewPhoto" class="preview-image mx-auto" style="max-width: 300px; max-height: 300px;">
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm font-medium text-gray-600">Pet Name:</label>
                                <p class="font-semibold" id="viewPetName" style="color: #2B2B2B;"></p>
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-600">Species:</label>
                                <p class="font-semibold" id="viewSpecies" style="color: #2B2B2B;"></p>
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-600">Last Seen Location:</label>
                            <p class="font-semibold" id="viewLocation" style="color: #2B2B2B;"></p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-600">Last Seen Date:</label>
                            <p class="font-semibold" id="viewDate" style="color: #2B2B2B;"></p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-600">Description:</label>
                            <p class="font-semibold whitespace-pre-line" id="viewDescription" style="color: #2B2B2B;"></p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-600">Report Created:</label>
                            <p class="font-semibold" id="viewCreatedAt" style="color: #2B2B2B;"></p>
                        </div>
                    </div>
                </div>
                <div class="flex justify-end pt-4">
                    <button onclick="closeModal('viewModal')" class="px-6 py-2 rounded-xl text-white font-medium hover:bg-[#24483E] transition duration-150 shadow-md" style="background-color: #2F5D50;">
                        Close
                    </button>
                </div>
            </div>
        </div>

        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />
        <script src="includes/sidebar.js"></script>
        <script>
                        // =======================================================
                        // Global Variables
                        // =======================================================
                        var currentUserId = <%= userId%>;
                        var currentUserName = "<%= userName != null ? userName : "User"%>";

                        var ITEMS_PER_PAGE = 10;
                        var currentPage = 1;
                        var filteredData = [];
                        var allLostReports = [];
                        var currentStatusFilter = 'all';
                        var currentReportId = null;
                        var isEditMode = false;
                        var selectedFile = null;

                        // =======================================================
                        // DOM Elements
                        // =======================================================
                        var errorMessage = document.getElementById('errorMessage');
                        var successMessage = document.getElementById('successMessage');
                        var searchInput = document.getElementById('searchInput');
                        var submitReportBtn = document.getElementById('submitReportBtn');

                        // =======================================================
                        // Initialization
                        // =======================================================
                        window.onload = function () {
                            loadLostReports();
                            attachEventListeners();

                            // Set today's date as max for date input
                            var today = new Date().toISOString().split('T')[0];
                            document.getElementById('lastSeenDate').max = today;

                            // Initialize file upload area click handler
                            document.getElementById('fileUploadArea').addEventListener('click', function () {
                                document.getElementById('petPhoto').click();
                            });
                        };

                        // =======================================================
                        // File Upload Functions
                        // =======================================================
                        function handleDragOver(event) {
                            event.preventDefault();
                            event.stopPropagation();
                            document.getElementById('fileUploadArea').classList.add('dragover');
                        }

                        function handleDragLeave(event) {
                            event.preventDefault();
                            event.stopPropagation();
                            document.getElementById('fileUploadArea').classList.remove('dragover');
                        }

                        function handleDrop(event) {
                            event.preventDefault();
                            event.stopPropagation();
                            document.getElementById('fileUploadArea').classList.remove('dragover');

                            var files = event.dataTransfer.files;
                            if (files.length > 0) {
                                handleFileSelect({target: {files: files}});
                            }
                        }

                        function handleFileSelect(event) {
                            var file = event.target.files[0];
                            if (file) {
                                // Validate file type
                                if (!file.type.match('image.*')) {
                                    showError('Please select an image file (JPG, PNG, GIF, etc.)');
                                    return;
                                }

                                // Validate file size (5MB limit)
                                if (file.size > 5 * 1024 * 1024) {
                                    showError('File size should be less than 5MB');
                                    return;
                                }

                                selectedFile = file;

                                // Show preview
                                var reader = new FileReader();
                                reader.onload = function (e) {
                                    document.getElementById('imagePreview').src = e.target.result;
                                    document.getElementById('uploadContent').classList.add('hidden');
                                    document.getElementById('previewContainer').classList.remove('hidden');
                                };
                                reader.readAsDataURL(file);
                            }
                        }

                        function removeImage() {
                            selectedFile = null;
                            document.getElementById('petPhoto').value = '';
                            document.getElementById('uploadContent').classList.remove('hidden');
                            document.getElementById('previewContainer').classList.add('hidden');
                            document.getElementById('currentImageInfo').classList.add('hidden');
                        }

                        // =======================================================
                        // API Functions
                        // =======================================================
                        function showError(msg) {
                            errorMessage.textContent = msg;
                            errorMessage.classList.remove('hidden');
                            setTimeout(function () {
                                errorMessage.classList.add('hidden');
                            }, 5000);
                        }

                        function showSuccess(msg) {
                            successMessage.textContent = msg;
                            successMessage.classList.remove('hidden');
                            setTimeout(function () {
                                successMessage.classList.add('hidden');
                            }, 5000);
                        }

                        // Load lost reports from backend
                        async function loadLostReports() {
                            try {
                                var response = await fetch('ManageLostAnimalServlet?action=getByAdopter');
                                var data = await response.json();

                                if (data.success) {
                                    allLostReports = data.reports || [];
                                    filteredData = [...allLostReports];

                                    updateCounts();
                                    updateFilterButtonStyles();
                                    renderTable(filteredData, currentPage);
                                    showSuccess('Loaded ' + allLostReports.length + ' lost reports');
                                } else {
                                    showError(data.message || 'Failed to load lost reports');
                                }
                            } catch (error) {
                                console.error('Error loading lost reports:', error);
                                showError('Network error. Please check your connection.');
                            }
                        }

                        // Get lost report details by ID
                        async function getLostReportDetails(lostId) {
                            try {
                                var response = await fetch('ManageLostAnimalServlet?action=getById&lostId=' + lostId);
                                var data = await response.json();

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
                            }
                        }

                        // Update lost report status
                        async function updateLostReportStatus(lostId, status) {
                            try {
                                var formData = new FormData();
                                formData.append('lostId', lostId);
                                formData.append('status', status);
                                formData.append('action', 'updateStatus');

                                var response = await fetch('ManageLostAnimalServlet', {
                                    method: 'POST',
                                    body: new URLSearchParams(formData)
                                });

                                var data = await response.json();

                                if (data.success) {
                                    showSuccess(data.message);
                                    await loadLostReports();
                                    return true;
                                } else {
                                    showError(data.message);
                                    return false;
                                }
                            } catch (error) {
                                console.error('Error updating status:', error);
                                showError('Network error. Please check your connection.');
                                return false;
                            }
                        }

                        // Update lost report
                        async function updateLostReport(reportId, reportData) {
                            try {
                                var formData = new FormData();
                                formData.append('lostId', reportId);
                                formData.append('action', 'update');
                                formData.append('pet_name', reportData.petName);
                                formData.append('species', reportData.species);
                                formData.append('last_seen_location', reportData.lastSeenLocation);
                                formData.append('last_seen_date', reportData.lastSeenDate);
                                formData.append('description', reportData.description);

                                // Only append file if selected
                                if (selectedFile) {
                                    formData.append('pet_photo', selectedFile);
                                }

                                var response = await fetch('ManageLostAnimalServlet', {
                                    method: 'POST',
                                    body: formData
                                });

                                var data = await response.json();

                                if (data.success) {
                                    showSuccess(data.message);
                                    await loadLostReports();
                                    return true;
                                } else {
                                    showError(data.message);
                                    return false;
                                }
                            } catch (error) {
                                console.error('Error updating report:', error);
                                showError('Network error. Please check your connection.');
                                return false;
                            }
                        }

                        // Create new lost report
                        async function createLostReport(reportData) {
                            try {
                                var formData = new FormData();
                                formData.append('action', 'create');
                                formData.append('pet_name', reportData.petName);
                                formData.append('species', reportData.species);
                                formData.append('last_seen_date', reportData.lastSeenDate);
                                formData.append('last_seen_location', reportData.lastSeenLocation);
                                formData.append('description', reportData.description);
                                formData.append('contact_info', reportData.contactInfo);

                                // Append file if selected
                                if (selectedFile) {
                                    formData.append('pet_photo', selectedFile);
                                }

                                var response = await fetch('ManageLostAnimalServlet', {
                                    method: 'POST',
                                    body: formData
                                });

                                var data = await response.json();

                                if (data.success) {
                                    showSuccess(data.message);
                                    await loadLostReports();
                                    return true;
                                } else {
                                    showError(data.message);
                                    return false;
                                }
                            } catch (error) {
                                console.error('Error creating report:', error);
                                showError('Network error. Please check your connection.');
                                return false;
                            }
                        }

                        // Delete lost report
                        async function deleteLostReport(reportId) {
                            try {
                                var formData = new FormData();
                                formData.append('lostId', reportId);
                                formData.append('action', 'delete');

                                var response = await fetch('ManageLostAnimalServlet', {
                                    method: 'POST',
                                    body: new URLSearchParams(formData)
                                });

                                var data = await response.json();

                                if (data.success) {
                                    showSuccess(data.message);
                                    await loadLostReports();
                                    return true;
                                } else {
                                    showError(data.message);
                                    return false;
                                }
                            } catch (error) {
                                console.error('Error deleting report:', error);
                                showError('Network error. Please check your connection.');
                                return false;
                            }
                        }

                        // =======================================================
                        // Modal Functions
                        // =======================================================
                        function openModal(modalId, reportId) {
                            var modal = document.getElementById(modalId);
                            currentReportId = reportId || null;

                            if (modalId === 'createModal') {
                                if (reportId) {
                                    // Edit mode
                                    isEditMode = true;
                                    document.getElementById('modalTitle').textContent = 'Edit Lost Pet Report';
                                    document.getElementById('lostId').value = reportId;
                                    loadReportForEdit(reportId);
                                } else {
                                    // Create mode
                                    isEditMode = false;
                                    document.getElementById('modalTitle').textContent = 'Report Lost Pet';
                                    document.getElementById('lostId').value = '';
                                    document.getElementById('reportForm').reset();
                                    removeImage();
                                    document.getElementById('currentImageInfo').classList.add('hidden');
                                }
                            } else if (modalId === 'foundModal' && reportId) {
                                var report = null;
                                for (var i = 0; i < allLostReports.length; i++) {
                                    if (allLostReports[i].lost_id === reportId) {
                                        report = allLostReports[i];
                                        break;
                                    }
                                }

                                if (report) {
                                    document.getElementById('foundPetName').textContent = report.pet_name;
                                    document.getElementById('confirmFoundBtn').onclick = function () {
                                        confirmMarkAsFound(reportId);
                                    };
                                }
                            } else if (modalId === 'deleteModal' && reportId) {
                                var report = null;
                                for (var i = 0; i < allLostReports.length; i++) {
                                    if (allLostReports[i].lost_id === reportId) {
                                        report = allLostReports[i];
                                        break;
                                    }
                                }

                                if (report) {
                                    document.getElementById('confirmDeleteBtn').onclick = function () {
                                        confirmDeleteReport(reportId);
                                    };
                                }
                            }

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
                                if (modalId === 'createModal') {
                                    document.getElementById('reportForm').reset();
                                    removeImage();
                                    document.getElementById('currentImageInfo').classList.add('hidden');
                                } else if (modalId === 'foundModal') {
                                    document.getElementById('foundNotes').value = '';
                                }
                            }, 300);
                        }

                        async function loadReportForEdit(reportId) {
                            try {
                                var report = await getLostReportDetails(reportId);
                                if (report) {
                                    document.getElementById('petName').value = report.pet_name;
                                    document.getElementById('species').value = report.species;
                                    document.getElementById('lastSeenLocation').value = report.last_seen_location;
                                    document.getElementById('lastSeenDate').value = report.last_seen_date;
                                    document.getElementById('description').value = report.description;

                                    // Extract contact info from description if available
                                    var description = report.description || '';
                                    var contactMatch = description.match(/Contact Information:\s*(.+)/);
                                    if (contactMatch) {
                                        document.getElementById('contactInfo').value = contactMatch[1].trim();
                                    }

                                    // Show current image info
                                    if (report.photo_path) {
                                        document.getElementById('currentImageInfo').classList.remove('hidden');

                                        // Show current image preview
                                        var currentImageUrl = report.photo_path;
                                        if (!currentImageUrl.startsWith('http') && !currentImageUrl.startsWith('/')) {
                                            currentImageUrl = currentImageUrl;
                                        }
                                        document.getElementById('imagePreview').src = currentImageUrl;
                                        document.getElementById('uploadContent').classList.add('hidden');
                                        document.getElementById('previewContainer').classList.remove('hidden');
                                    }
                                }
                            } catch (error) {
                                console.error('Error loading report for edit:', error);
                                showError('Failed to load report data');
                            }
                        }

                        async function saveReport() {
                            var petName = document.getElementById('petName').value;
                            var species = document.getElementById('species').value;
                            var lastSeenLocation = document.getElementById('lastSeenLocation').value;
                            var lastSeenDate = document.getElementById('lastSeenDate').value;
                            var description = document.getElementById('description').value;
                            var contactInfo = document.getElementById('contactInfo').value;

                            if (!petName || !species || !lastSeenLocation || !lastSeenDate || !contactInfo) {
                                showError('Please fill in all required fields!');
                                return;
                            }

                            // Combine description with contact info
                            var fullDescription = (description || '') + '\n\nContact Information: ' + contactInfo;

                            // Disable submit button temporarily
                            var originalText = submitReportBtn.innerHTML;
                            submitReportBtn.disabled = true;
                            submitReportBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Processing...';

                            if (isEditMode && currentReportId) {
                                // Update existing report
                                var reportData = {
                                    petName: petName,
                                    species: species,
                                    lastSeenLocation: lastSeenLocation,
                                    lastSeenDate: lastSeenDate,
                                    description: fullDescription
                                };

                                var success = await updateLostReport(currentReportId, reportData);
                                if (success) {
                                    closeModal('createModal');
                                }
                            } else {
                                // Create new report
                                var reportData = {
                                    petName: petName,
                                    species: species,
                                    lastSeenLocation: lastSeenLocation,
                                    lastSeenDate: lastSeenDate,
                                    description: fullDescription,
                                    contactInfo: contactInfo
                                };

                                var success = await createLostReport(reportData);
                                if (success) {
                                    closeModal('createModal');
                                }
                            }

                            // Re-enable submit button
                            submitReportBtn.disabled = false;
                            submitReportBtn.innerHTML = originalText;
                        }

                        async function confirmMarkAsFound(reportId) {
                            try {
                                var success = await updateLostReportStatus(reportId, 'found');
                                if (success) {
                                    closeModal('foundModal');
                                }
                            } catch (error) {
                                console.error('Error marking as found:', error);
                                showError('Failed to update status');
                            }
                        }

                        async function confirmDeleteReport(reportId) {
                            try {
                                var success = await deleteLostReport(reportId);
                                if (success) {
                                    closeModal('deleteModal');
                                }
                            } catch (error) {
                                console.error('Error deleting report:', error);
                                showError('Failed to delete report');
                            }
                        }

                        // =======================================================
                        // Rendering Functions
                        // =======================================================
                        function getStatusChipClass(status) {
                            return status === 'lost' ? 'chip-lost' : 'chip-found';
                        }

                        function formatDate(dateString) {
                            if (!dateString)
                                return 'N/A';
                            var date = new Date(dateString);
                            return date.toLocaleDateString('en-US', {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric'
                            });
                        }

                        function renderTable(data, page) {
                            var tableBody = document.getElementById('lost-animal-list');
                            tableBody.innerHTML = '';

                            var start = (page - 1) * ITEMS_PER_PAGE;
                            var end = start + ITEMS_PER_PAGE;
                            var paginatedItems = data.slice(start, end);

                            if (paginatedItems.length === 0) {
                                var noDataRow = '<tr>' +
                                        '<td colspan="7" class="px-6 py-12 text-center">' +
                                        '<i class="fas fa-search text-5xl text-gray-300 mb-4"></i>' +
                                        '<h3 class="text-xl font-semibold text-gray-600 mb-2">No lost reports found</h3>' +
                                        '<p class="text-gray-500">Try adjusting your filters or report a new lost pet.</p>' +
                                        '</td>' +
                                        '</tr>';
                                tableBody.innerHTML = noDataRow;
                            } else {
                                for (var i = 0; i < paginatedItems.length; i++) {
                                    var item = paginatedItems[i];
                                    var statusChipClass = getStatusChipClass(item.status);
                                    var itemNumber = start + i + 1;

                                    var actionButtons;
                                    if (item.status === 'lost') {
                                        actionButtons = '<div class="flex flex-col items-center space-y-2">' +
                                                '<button onclick="openModal(\'createModal\', ' + item.lost_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View/Edit</button>' +
                                                '<button onclick="openModal(\'foundModal\', ' + item.lost_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-green-700" style="background-color: #57A677;">Mark as Found</button>' +
                                                '<button onclick="openModal(\'deleteModal\', ' + item.lost_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-red-800" style="background-color: #B84A4A;">Delete</button>' +
                                                '</div>';
                                    } else {
                                        actionButtons = '<button onclick="showViewDetails(' + item.lost_id + ')" class="action-button px-3 py-1 rounded-lg font-semibold text-white hover:bg-[#24483E]" style="background-color: #2F5D50;">View Details</button>';
                                    }

                                    var row = '<tr class="hover:bg-gray-50 transition duration-100">' +
                                            '<td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;">' + itemNumber + '</td>' +
                                            '<td class="px-6 py-4 whitespace-nowrap">' +
                                            '<div class="flex items-center">' +
                                            '<div class="flex-shrink-0 h-10 w-10">' +
                                            '<img class="h-10 w-10 rounded-full object-cover" src="' + (item.photo_path || 'lost_picture/default_lost_pet.jpg') + '" alt="' + item.pet_name + '" onerror="this.src=\'lost_picture/default_lost_pet.jpg\'">' +
                                            '</div>' +
                                            '<div class="ml-4">' +
                                            '<div class="text-sm font-medium" style="color: #2B2B2B;">' + item.pet_name + '</div>' +
                                            '</div>' +
                                            '</div>' +
                                            '</td>' +
                                            '<td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">' + (item.species ? item.species.charAt(0).toUpperCase() + item.species.slice(1) : 'Unknown') + '</td>' +
                                            '<td class="px-6 py-4 text-sm" style="color: #2B2B2B;">' + (item.last_seen_location || 'Location not specified') + '</td>' +
                                            '<td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">' + formatDate(item.last_seen_date) + '</td>' +
                                            '<td class="px-6 py-4 whitespace-nowrap">' +
                                            '<span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ' + statusChipClass + '">' +
                                            (item.status === 'lost' ? '🔴 Lost' : '✅ Found') +
                                            '</span>' +
                                            '</td>' +
                                            '<td class="px-6 py-4 whitespace-nowrap text-center">' +
                                            actionButtons +
                                            '</td>' +
                                            '</tr>';

                                    tableBody.innerHTML += row;
                                }
                            }

                            renderPaginationControls(data.length);
                        }

                        async function showViewDetails(reportId) {
                            try {
                                var report = await getLostReportDetails(reportId);
                                if (report) {
                                    document.getElementById('viewPetName').textContent = report.pet_name;
                                    document.getElementById('viewSpecies').textContent = report.species ? report.species.charAt(0).toUpperCase() + report.species.slice(1) : 'Unknown';
                                    document.getElementById('viewLocation').textContent = report.last_seen_location || 'Not specified';
                                    document.getElementById('viewDate').textContent = formatDate(report.last_seen_date);
                                    document.getElementById('viewDescription').textContent = report.description || 'No description provided.';
                                    document.getElementById('viewCreatedAt').textContent = formatDate(report.created_at);

                                    // Set photo
                                    var photoUrl = report.photo_path || 'lost_picture/default_lost_pet.jpg';
                                    document.getElementById('viewPhoto').src = photoUrl;

                                    openModal('viewModal');
                                }
                            } catch (error) {
                                console.error('Error showing view details:', error);
                                showError('Failed to load report details');
                            }
                        }

                        // =======================================================
                        // Pagination & Filtering Functions
                        // =======================================================
                        function renderPaginationControls(totalItems) {
                            var totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
                            document.getElementById('total-items').textContent = totalItems;
                            document.getElementById('start-index').textContent = totalItems === 0 ? 0 : Math.min(totalItems, (currentPage - 1) * ITEMS_PER_PAGE + 1);
                            document.getElementById('end-index').textContent = Math.min(totalItems, currentPage * ITEMS_PER_PAGE);
                            document.getElementById('prev-btn').disabled = currentPage === 1;
                            document.getElementById('next-btn').disabled = currentPage === totalPages || totalItems === 0;
                        }

                        function updateCounts() {
                            var counts = {
                                'all': allLostReports.length,
                                'lost': 0,
                                'found': 0
                            };

                            for (var i = 0; i < allLostReports.length; i++) {
                                var status = allLostReports[i].status;
                                if (status === 'lost') {
                                    counts.lost++;
                                } else if (status === 'found') {
                                    counts.found++;
                                }
                            }

                            document.getElementById('countAll').textContent = counts.all;
                            document.getElementById('countLost').textContent = counts.lost;
                            document.getElementById('countFound').textContent = counts.found;
                        }

                        function updateFilterButtonStyles() {
                            var filterButtons = document.querySelectorAll('.filter-btn');

                            for (var i = 0; i < filterButtons.length; i++) {
                                var btn = filterButtons[i];
                                var btnStatus = btn.getAttribute('data-status');

                                // Reset semua classes
                                btn.className = 'px-5 py-2 rounded-full text-sm font-medium transition duration-150 filter-btn';

                                // Set active button
                                if (btnStatus === currentStatusFilter) {
                                    if (btnStatus === 'all') {
                                        btn.classList.add('bg-primary', 'text-white', 'shadow-md');
                                    } else if (btnStatus === 'lost') {
                                        btn.classList.add('chip-lost', 'shadow-md');
                                    } else if (btnStatus === 'found') {
                                        btn.classList.add('chip-found', 'shadow-md');
                                    }
                                } else {
                                    btn.classList.add('border', 'hover:bg-[#F6F3E7]');
                                    if (btnStatus === 'all') {
                                        btn.classList.add('border-[#2F5D50]', 'text-[#2F5D50]');
                                    } else if (btnStatus === 'lost') {
                                        btn.classList.add('border-[#B84A4A]', 'text-[#B84A4A]');
                                    } else if (btnStatus === 'found') {
                                        btn.classList.add('border-[#6DBF89]', 'text-[#57A677]');
                                    }
                                }
                            }
                        }

                        function filterAndRender() {
                            if (currentStatusFilter === 'all') {
                                filteredData = allLostReports;
                            } else {
                                filteredData = [];
                                for (var i = 0; i < allLostReports.length; i++) {
                                    if (allLostReports[i].status === currentStatusFilter) {
                                        filteredData.push(allLostReports[i]);
                                    }
                                }
                            }

                            // Apply search filter if exists
                            var searchTerm = searchInput.value.toLowerCase().trim();
                            if (searchTerm !== '') {
                                var searchFiltered = [];
                                for (var j = 0; j < filteredData.length; j++) {
                                    if (filteredData[j].pet_name && filteredData[j].pet_name.toLowerCase().indexOf(searchTerm) !== -1) {
                                        searchFiltered.push(filteredData[j]);
                                    }
                                }
                                filteredData = searchFiltered;
                            }

                            currentPage = 1;
                            renderTable(filteredData, currentPage);
                        }

                        // =======================================================
                        // Event Listeners
                        // =======================================================
                        function attachEventListeners() {
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

                            // Filter buttons
                            var filterButtons = document.querySelectorAll('.filter-btn');
                            for (var i = 0; i < filterButtons.length; i++) {
                                filterButtons[i].addEventListener('click', function (e) {
                                    currentStatusFilter = this.getAttribute('data-status');
                                    updateFilterButtonStyles();
                                    filterAndRender();
                                });
                            }

                            // Search input
                            searchInput.addEventListener('input', function () {
                                filterAndRender();
                            });
                        }
        </script>
    </body>
</html>