<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="javax.servlet.http.HttpServletRequest" %> <!-- TAMBAH INI -->
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<%
    // FORCE LOAD THROUGH SERVLET IF NO DATA
    if (request.getAttribute("banners") == null) {
        RequestDispatcher dispatcher = request.getRequestDispatcher("ManageBannerServlet");
        dispatcher.forward(request, response);
        return;
    }

    // Check if user is logged in and is admin
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isAdmin(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Dapatkan context path untuk gambar
    String contextPath = request.getContextPath();
    pageContext.setAttribute("contextPath", contextPath);
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Manage Banners - Rimba Adopt Admin</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
            .banner-preview {
                transition: all 0.3s ease;
            }

            .banner-preview:hover {
                transform: translateY(-5px);
                box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            }

            .sortable-ghost {
                opacity: 0.4;
            }

            .sortable-drag {
                opacity: 0.8;
                transform: rotate(5deg);
            }

            .upload-area {
                border: 2px dashed #E5E5E5;
                border-radius: 12px;
                transition: all 0.3s ease;
            }

            .upload-area:hover, .upload-area.dragover {
                border-color: #2F5D50;
                background-color: rgba(47, 93, 80, 0.05);
            }

            .image-preview {
                border-radius: 8px;
                overflow: hidden;
                background-color: #F6F3E7;
            }

            .status-badge {
                display: inline-block;
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 500;
            }

            .success-message {
                animation: fadeOut 5s forwards;
            }

            @keyframes fadeOut {
                0% { opacity: 1; }
                70% { opacity: 1; }
                100% { opacity: 0; display: none; }
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Main Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Success/Error Messages -->
                <c:if test="${not empty param.success}">
                    <div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg success-message">
                        <div class="flex items-center">
                            <svg class="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                            </svg>
                            <span class="text-green-700">${param.success}</span>
                        </div>
                    </div>
                </c:if>

                <c:if test="${not empty param.error}">
                    <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
                        <div class="flex items-center">
                            <svg class="w-5 h-5 text-red-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                            </svg>
                            <span class="text-red-700">${param.error}</span>
                        </div>
                    </div>
                </c:if>

                <!-- Page Header -->
                <div class="mb-8 pb-4 border-b border-[#E5E5E5]">
                    <div class="flex items-center justify-between">
                        <div>
                            <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Manage Banners</h1>
                            <p class="mt-2 text-lg" style="color: #2B2B2B;">
                                Upload, organize, and manage homepage banner images
                            </p>
                        </div>
                        <a href="dashboard_admin.jsp" class="flex items-center gap-2 px-4 py-2 rounded-lg text-white hover:bg-[#24483E] transition" style="background-color: #2F5D50;">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
                            </svg>
                            <span>Back to Dashboard</span>
                        </a>
                    </div>
                </div>

                <!-- Stats Overview -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium" style="color: #2F5D50;">Total Banners</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;">${totalCount}</p>
                        <p class="text-xs text-gray-500 mt-1">Active on homepage</p>
                    </div>

                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <p class="text-sm font-medium" style="color: #57A677;">Storage Used</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;">
                            <c:choose>
                                <c:when test="${totalStorage lt 1024}">
                                    ${totalStorage} Bytes
                                </c:when>
                                <c:when test="${totalStorage lt 1048576}">
                                    <fmt:formatNumber value="${totalStorage / 1024}" pattern="#.##"/> KB
                                </c:when>
                                <c:otherwise>
                                    <fmt:formatNumber value="${totalStorage / 1048576}" pattern="#.##"/> MB
                                </c:otherwise>
                            </c:choose>
                        </p>
                        <p class="text-xs text-gray-500 mt-1">of 50 MB available</p>
                    </div>

                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <p class="text-sm font-medium" style="color: #C49A6C;">Active Banners</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;">${activeCount}</p>
                        <p class="text-xs text-gray-500 mt-1">currently visible</p>
                    </div>

                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                        <p class="text-sm font-medium" style="color: #B84A4A;">Max Banners</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;">10</p>
                        <p class="text-xs text-gray-500 mt-1">maximum allowed</p>
                    </div>
                </div>

                <!-- Main Content Grid -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- Left Column: Banner List -->
                    <div class="lg:col-span-2">
                        <!-- Active Banners Section -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm mb-6">
                            <div class="flex items-center justify-between mb-6">
                                <h2 class="text-xl font-semibold" style="color: #2B2B2B;">All Banners</h2>
                                <div class="flex items-center gap-2">
                                    <span class="text-sm" style="color: #2B2B2B;">Drag to reorder</span>
                                    <svg class="w-5 h-5" style="color: #2F5D50;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"/>
                                    </svg>
                                </div>
                            </div>

                            <!-- Banner List -->
                            <div class="space-y-4" id="bannerList">
                                <c:forEach var="banner" items="${banners}" varStatus="loop">
                                    <div class="banner-item flex items-center gap-4 p-4 border border-[#E5E5E5] rounded-lg hover:bg-[#F6F3E7] transition cursor-move" data-id="${banner.bannerId}">
                                        <div class="flex-shrink-0">
                                            <span class="w-10 h-10 rounded-lg flex items-center justify-center" style="background-color: #2F5D50; color: white; font-weight: bold;">
                                                ${banner.displayOrder}
                                            </span>
                                        </div>
                                        <div class="image-preview w-24 h-16 flex-shrink-0">
                                            <!-- FIXED IMAGE DISPLAY -->
                                            <c:set var="imageUrl" value="${contextPath}/${banner.imagePath}" />
                                            <img src="${imageUrl}" 
                                                 alt="${banner.title}" 
                                                 class="w-full h-full object-cover"
                                                 onerror="this.onerror=null; this.src='${contextPath}/images/placeholder-banner.png';">
                                        </div>
                                        <div class="flex-1 min-w-0">
                                            <div class="flex items-center justify-between">
                                                <div>
                                                    <h3 class="font-medium" style="color: #2B2B2B;">${banner.title}</h3>
                                                    <p class="text-sm text-gray-500">
                                                        ${banner.fileName} • ${banner.imageDimensions} • 
                                                        <c:choose>
                                                            <c:when test="${empty banner.fileSize or banner.fileSize eq 0}">
                                                                N/A
                                                            </c:when>
                                                            <c:when test="${banner.fileSize lt 1024}">
                                                                ${banner.fileSize} Bytes
                                                            </c:when>
                                                            <c:when test="${banner.fileSize lt 1048576}">
                                                                <fmt:formatNumber value="${banner.fileSize / 1024}" pattern="#.##"/> KB
                                                            </c:when>
                                                            <c:otherwise>
                                                                <fmt:formatNumber value="${banner.fileSize / 1048576}" pattern="#.##"/> MB
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </p>
                                                </div>
                                                <div class="flex items-center gap-2">
                                                    <span class="status-badge" 
                                                          style="background-color: ${banner.status eq 'visible' ? '#6DBF89' : '#C49A6C'}; 
                                                          color: ${banner.status eq 'visible' ? '#06321F' : '#5D4037'}">
                                                        ${banner.status eq 'visible' ? 'Active' : 'Hidden'}
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="mt-2">
                                                <input type="text" class="w-full px-3 py-2 border border-[#E5E5E5] rounded text-sm caption-input" 
                                                       value="${banner.caption}" placeholder="Banner caption" 
                                                       data-id="${banner.bannerId}">
                                            </div>
                                        </div>
                                        <div class="flex items-center gap-2 flex-shrink-0">
                                            <button class="p-2 hover:bg-[#E5E5E5] rounded transition preview-btn" title="Preview" data-id="${banner.bannerId}" data-caption="${banner.caption}" data-title="${banner.title}">
                                                <svg class="w-5 h-5" style="color: #2F5D50;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                                </svg>
                                            </button>
                                            <button class="p-2 hover:bg-red-50 rounded transition delete-banner" title="Delete" data-id="${banner.bannerId}" data-title="${banner.title}">
                                                <svg class="w-5 h-5" style="color: #B84A4A;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                </c:forEach>

                                <c:if test="${empty banners}">
                                    <div class="text-center py-8">
                                        <svg class="w-16 h-16 mx-auto text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                        </svg>
                                        <p class="mt-4 text-gray-500">No banners found. Upload your first banner!</p>
                                    </div>
                                </c:if>
                            </div>

                            <!-- Save Order Button -->
                            <div class="mt-6 pt-4 border-t border-[#E5E5E5] flex justify-end">
                                <button id="saveOrderBtn" class="px-6 py-2 text-white rounded-lg hover:bg-[#24483E] transition" style="background-color: #2F5D50;">
                                    Save Banner Order
                                </button>
                            </div>
                        </div>

                        <!-- Preview Section -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm">
                            <h2 class="text-xl font-semibold mb-4" style="color: #2B2B2B;">Banner Preview</h2>
                            <p class="text-sm text-gray-500 mb-4">How your banners will appear on the homepage</p>

                            <div class="relative overflow-hidden rounded-lg" style="height: 250px; background-color: #F6F3E7;">
                                <div id="bannerPreview" class="absolute inset-0">
                                    <div class="banner-preview-slide active">
                                        <div class="w-full h-full bg-gradient-to-r from-[#2F5D50] to-[#57A677] flex items-center justify-center">
                                            <div class="text-center text-white p-6">
                                                <h3 class="text-2xl font-bold mb-2">No banners available</h3>
                                                <p class="opacity-90">Upload your first banner to see preview</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Preview Navigation -->
                                <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2" id="previewDots">
                                    <!-- Dots will be generated dynamically -->
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Right Column: Upload & Settings -->
                    <div class="lg:col-span-1">
                        <!-- Upload New Banner -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm mb-6">
                            <h2 class="text-xl font-semibold mb-4" style="color: #2B2B2B;">Upload New Banner</h2>
                            <p class="text-sm text-gray-500 mb-4">Upload a new image to add to your banner rotation</p>

                            <form id="uploadForm" enctype="multipart/form-data" method="POST" action="ManageBannerServlet">
                                <input type="hidden" name="action" value="add">

                                <div class="upload-area p-8 text-center mb-4" id="uploadArea">
                                    <svg class="w-12 h-12 mx-auto mb-4" style="color: #2F5D50;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                    </svg>
                                    <p class="font-medium mb-1" style="color: #2B2B2B;">Drag & drop your image here</p>
                                    <p class="text-sm text-gray-500 mb-4">or click to browse</p>
                                    <input type="file" id="bannerUpload" name="bannerImage" accept="image/*" class="hidden">
                                    <label for="bannerUpload" class="inline-block px-4 py-2 text-white rounded-lg cursor-pointer hover:bg-[#24483E] transition" style="background-color: #2F5D50;">
                                        Choose File
                                    </label>
                                    <p class="text-xs text-gray-500 mt-4">Supports: JPG, PNG, GIF • Max size: 5MB • Recommended: 1920x400px</p>
                                </div>

                                <!-- File Preview (hidden by default) -->
                                <div id="filePreview" class="hidden">
                                    <div class="mb-4">
                                        <div class="image-preview w-full h-40 mb-2">
                                            <img id="previewImage" class="w-full h-full object-cover">
                                        </div>
                                        <p id="fileName" class="text-sm font-medium" style="color: #2B2B2B;"></p>
                                        <p id="fileSize" class="text-xs text-gray-500"></p>
                                    </div>

                                    <!-- Banner Details Form -->
                                    <div class="space-y-4">
                                        <div>
                                            <label class="block text-sm font-medium mb-1" style="color: #2B2B2B;">Banner Title</label>
                                            <input type="text" id="bannerTitle" name="title" class="w-full px-3 py-2 border border-[#E5E5E5] rounded" placeholder="Enter banner title" required>
                                        </div>

                                        <div>
                                            <label class="block text-sm font-medium mb-1" style="color: #2B2B2B;">Caption Text</label>
                                            <input type="text" id="bannerCaption" name="caption" class="w-full px-3 py-2 border border-[#E5E5E5] rounded" placeholder="Enter caption text" required>
                                        </div>

                                        <div>
                                            <label class="block text-sm font-medium mb-1" style="color: #2B2B2B;">Position</label>
                                            <select id="bannerPosition" name="position" class="w-full px-3 py-2 border border-[#E5E5E5] rounded">
                                                <option value="1">Position 1 (First)</option>
                                                <option value="2">Position 2</option>
                                                <option value="3">Position 3</option>
                                                <option value="4">Position 4</option>
                                                <option value="5">Position 5</option>
                                                <option value="6">Position 6 (Last)</option>
                                            </select>
                                        </div>

                                        <div>
                                            <label class="flex items-center">
                                                <input type="checkbox" id="bannerActive" name="active" value="visible" class="mr-2" checked>
                                                <span class="text-sm" style="color: #2B2B2B;">Set as active immediately</span>
                                            </label>
                                        </div>

                                        <div class="flex gap-2 pt-2">
                                            <button type="button" id="cancelUpload" class="flex-1 px-4 py-2 border border-[#E5E5E5] rounded-lg hover:bg-[#F6F3E7] transition" style="color: #2B2B2B;">
                                                Cancel
                                            </button>
                                            <button type="submit" id="uploadBanner" class="flex-1 px-4 py-2 text-white rounded-lg hover:bg-[#24483E] transition" style="background-color: #2F5D50;">
                                                Upload Banner
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </form>
                        </div>

                        <!-- Banner Settings -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm">
                            <h2 class="text-xl font-semibold mb-4" style="color: #2B2B2B;">Banner Settings</h2>

                            <div class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium mb-1" style="color: #2B2B2B;">Transition Speed</label>
                                    <select id="transitionSpeed" class="w-full px-3 py-2 border border-[#E5E5E5] rounded">
                                        <option value="3000">3 seconds</option>
                                        <option value="5000" selected>5 seconds</option>
                                        <option value="7000">7 seconds</option>
                                        <option value="10000">10 seconds</option>
                                    </select>
                                </div>

                                <div>
                                    <label class="block text-sm font-medium mb-1" style="color: #2B2B2B;">Animation Type</label>
                                    <select id="animationType" class="w-full px-3 py-2 border border-[#E5E5E5] rounded">
                                        <option value="fade">Fade</option>
                                        <option value="slide" selected>Slide</option>
                                        <option value="zoom">Zoom</option>
                                    </select>
                                </div>

                                <div>
                                    <label class="flex items-center">
                                        <input type="checkbox" id="autoPlay" class="mr-2" checked>
                                        <span class="text-sm" style="color: #2B2B2B;">Auto-play banners</span>
                                    </label>
                                </div>

                                <div>
                                    <label class="flex items-center">
                                        <input type="checkbox" id="showArrows" class="mr-2" checked>
                                        <span class="text-sm" style="color: #2B2B2B;">Show navigation arrows</span>
                                    </label>
                                </div>

                                <div>
                                    <label class="flex items-center">
                                        <input type="checkbox" id="showDots" class="mr-2" checked>
                                        <span class="text-sm" style="color: #2B2B2B;">Show indicator dots</span>
                                    </label>
                                </div>

                                <div class="pt-4 border-t border-[#E5E5E5]">
                                    <button id="saveSettingsBtn" class="w-full px-4 py-2 text-white rounded-lg hover:bg-[#24483E] transition" style="background-color: #2F5D50;">
                                        Save Settings
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
            // File Upload Handling
            var uploadArea = document.getElementById('uploadArea');
            var fileInput = document.getElementById('bannerUpload');
            var filePreview = document.getElementById('filePreview');
            var previewImage = document.getElementById('previewImage');
            var fileName = document.getElementById('fileName');
            var fileSize = document.getElementById('fileSize');
            var cancelUploadBtn = document.getElementById('cancelUpload');
            var uploadBannerBtn = document.getElementById('uploadBanner');
            var saveOrderBtn = document.getElementById('saveOrderBtn');
            var uploadForm = document.getElementById('uploadForm');

            // Drag and drop events
            uploadArea.addEventListener('dragover', function (e) {
                e.preventDefault();
                uploadArea.classList.add('dragover');
            });

            uploadArea.addEventListener('dragleave', function () {
                uploadArea.classList.remove('dragover');
            });

            uploadArea.addEventListener('drop', function (e) {
                e.preventDefault();
                uploadArea.classList.remove('dragover');
                if (e.dataTransfer.files.length) {
                    fileInput.files = e.dataTransfer.files;
                    handleFileSelect(e.dataTransfer.files[0]);
                }
            });

            // Click to upload
            uploadArea.addEventListener('click', function () {
                fileInput.click();
            });

            fileInput.addEventListener('change', function (e) {
                if (e.target.files.length) {
                    handleFileSelect(e.target.files[0]);
                }
            });

            // Handle file selection
            function handleFileSelect(file) {
                // Check file type
                if (!file.type.match('image.*')) {
                    alert('Please select an image file');
                    return;
                }

                // Check file size (5MB max)
                if (file.size > 5 * 1024 * 1024) {
                    alert('File size must be less than 5MB');
                    return;
                }

                // Show preview
                var reader = new FileReader();
                reader.onload = function (e) {
                    previewImage.src = e.target.result;
                    fileName.textContent = file.name;
                    fileSize.textContent = formatFileSize(file.size);
                    filePreview.classList.remove('hidden');
                };
                reader.readAsDataURL(file);
            }

            // Format file size
            function formatFileSize(bytes) {
                if (bytes === 0)
                    return '0 Bytes';
                var k = 1024;
                var sizes = ['Bytes', 'KB', 'MB', 'GB'];
                var i = Math.floor(Math.log(bytes) / Math.log(k));
                return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
            }

            // Cancel upload
            cancelUploadBtn.addEventListener('click', function () {
                filePreview.classList.add('hidden');
                fileInput.value = '';
                uploadForm.reset();
            });

            // Form submission
            uploadForm.addEventListener('submit', function (e) {
                var title = document.getElementById('bannerTitle').value;
                var caption = document.getElementById('bannerCaption').value;
                var file = fileInput.files[0];

                if (!title.trim()) {
                    e.preventDefault();
                    alert('Please enter a banner title');
                    return;
                }

                if (!caption.trim()) {
                    e.preventDefault();
                    alert('Please enter a caption text');
                    return;
                }

                if (!file) {
                    e.preventDefault();
                    alert('Please select an image file');
                    return;
                }

                // Show loading state
                uploadBannerBtn.innerHTML = 'Uploading...';
                uploadBannerBtn.disabled = true;
            });

            // AJAX for updating caption
            document.querySelectorAll('.caption-input').forEach(function (input) {
                input.addEventListener('blur', function () {
                    var bannerId = this.getAttribute('data-id');
                    var caption = this.value;

                    // Send AJAX request
                    fetch('ManageBannerServlet', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: new URLSearchParams({
                            action: 'update_caption',
                            banner_id: bannerId,
                            caption: caption
                        })
                    })
                            .then(response => response.json())
                            .then(data => {
                                if (data.status !== 'success') {
                                    console.error('Error updating caption:', data.message);
                                }
                            })
                            .catch(error => {
                                console.error('Error:', error);
                            });
                });
            });

            // Save order functionality
            saveOrderBtn.addEventListener('click', function () {
                saveOrderBtn.textContent = 'Saving...';
                saveOrderBtn.disabled = true;

                var bannerIds = [];
                document.querySelectorAll('.banner-item').forEach(function (item) {
                    bannerIds.push(item.getAttribute('data-id'));
                });

                if (bannerIds.length === 0) {
                    alert('No banners to save');
                    saveOrderBtn.textContent = 'Save Banner Order';
                    saveOrderBtn.disabled = false;
                    return;
                }

                // Send AJAX request
                fetch('ManageBannerServlet', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: (function () {
                        var params = new URLSearchParams();
                        params.append('action', 'save_order');
                        bannerIds.forEach(function (id) {
                            params.append('banner_ids[]', id);
                        });
                        return params;
                    })()
                })
                        .then(response => response.json())
                        .then(data => {
                            if (data.status === 'success') {
                                alert('Banner order saved successfully!');
                                // Update display numbers
                                updateBannerNumbers();
                            } else {
                                alert('Error saving order: ' + (data.message || ''));
                            }
                            saveOrderBtn.textContent = 'Save Banner Order';
                            saveOrderBtn.disabled = false;
                        })
                        .catch(error => {
                            console.error('Error:', error);
                            alert('Error saving order');
                            saveOrderBtn.textContent = 'Save Banner Order';
                            saveOrderBtn.disabled = false;
                        });
            });

            // Delete banner
            document.querySelectorAll('.delete-banner').forEach(function (button) {
                button.addEventListener('click', function (e) {
                    e.stopPropagation();
                    var bannerId = this.getAttribute('data-id');
                    var bannerName = this.getAttribute('data-title');

                    if (confirm('Are you sure you want to delete "' + bannerName + '"?')) {
                        // Show loading
                        this.closest('.banner-item').style.opacity = '0.5';

                        // Delete via AJAX
                        fetch('ManageBannerServlet?action=delete&banner_id=' + bannerId)
                                .then(response => {
                                    console.log('Delete response status:', response.status);
                                    if (response.redirected || response.url.includes('success=')) {
                                        // Remove from DOM
                                        this.closest('.banner-item').remove();
                                        updateBannerNumbers();

                                        // Reload page to update stats
                                        setTimeout(function () {
                                            window.location.href = 'ManageBannerServlet?success=Banner+deleted+successfully';
                                        }, 500);
                                    } else {
                                        alert('Error deleting banner');
                                        this.closest('.banner-item').style.opacity = '1';
                                    }
                                })
                                .catch(error => {
                                    console.error('Error:', error);
                                    alert('Error deleting banner');
                                    this.closest('.banner-item').style.opacity = '1';
                                });
                    }
                });
            });

            // Update banner numbers after delete/reorder
            function updateBannerNumbers() {
                var banners = document.querySelectorAll('.banner-item');
                banners.forEach(function (banner, index) {
                    var numberSpan = banner.querySelector('.flex-shrink-0 span');
                    numberSpan.textContent = index + 1;
                    numberSpan.style.backgroundColor = '#2F5D50';
                });
            }

            // Simple drag and drop (without external library)
            var draggedItem = null;

            document.querySelectorAll('.banner-item').forEach(function (item) {
                item.setAttribute('draggable', 'true');

                item.addEventListener('dragstart', function (e) {
                    draggedItem = this;
                    setTimeout(function () {
                        item.style.opacity = '0.4';
                    }, 0);
                });

                item.addEventListener('dragend', function () {
                    setTimeout(function () {
                        item.style.opacity = '1';
                        draggedItem = null;
                    }, 0);
                });

                item.addEventListener('dragover', function (e) {
                    e.preventDefault();
                });

                item.addEventListener('dragenter', function (e) {
                    e.preventDefault();
                    if (this !== draggedItem) {
                        this.style.backgroundColor = '#E8F5EE';
                    }
                });

                item.addEventListener('dragleave', function () {
                    this.style.backgroundColor = '';
                });

                item.addEventListener('drop', function (e) {
                    e.preventDefault();
                    if (this !== draggedItem) {
                        var allItems = Array.prototype.slice.call(document.querySelectorAll('.banner-item'));
                        var draggedIndex = allItems.indexOf(draggedItem);
                        var targetIndex = allItems.indexOf(this);

                        if (draggedIndex < targetIndex) {
                            this.parentNode.insertBefore(draggedItem, this.nextSibling);
                        } else {
                            this.parentNode.insertBefore(draggedItem, this);
                        }

                        updateBannerNumbers();
                    }
                    this.style.backgroundColor = '';
                });
            });

            // Banner preview functionality
            var previewIndex = 0;
            var previewInterval;
            var banners = [];
            <c:forEach var="banner" items="${banners}" varStatus="loop">
            banners.push({
                id: ${banner.bannerId},
                title: "<c:out value='${banner.title}' escapeXml='true'/>",
                caption: "<c:out value='${banner.caption}' escapeXml='true'/>",
                imagePath: "<c:out value='${banner.imagePath}' escapeXml='true'/>",
                status: "${banner.status}"
            });
            </c:forEach>

            console.log('Banners loaded:', banners.length);

            // Color gradients for preview
            var previewColors = [
                'from-[#2F5D50] to-[#57A677]',
                'from-[#C49A6C] to-[#F59E0B]',
                'from-[#8B5CF6] to-[#EC4899]',
                'from-[#3B82F6] to-[#1D4ED8]',
                'from-[#10B981] to-[#047857]',
                'from-[#EF4444] to-[#DC2626]',
                'from-[#8B5CF6] to-[#7C3AED]',
                'from-[#EC4899] to-[#DB2777]',
                'from-[#14B8A6] to-[#0D9488]',
                'from-[#F59E0B] to-[#D97706]'
            ];

            function updatePreview() {
                var previewContainer = document.getElementById('bannerPreview');
                var dotsContainer = document.getElementById('previewDots');

                if (banners.length === 0) {
                    previewContainer.innerHTML = '' +
                            '<div class="banner-preview-slide active w-full h-full">' +
                            '<div class="w-full h-full bg-gradient-to-r from-[#2F5D50] to-[#57A677] flex items-center justify-center">' +
                            '<div class="text-center text-white p-6">' +
                            '<h3 class="text-2xl font-bold mb-2">No banners available</h3>' +
                            '<p class="opacity-90">Upload your first banner to see preview</p>' +
                            '</div>' +
                            '</div>' +
                            '</div>';
                    dotsContainer.innerHTML = '';
                    return;
                }

                var currentBanner = banners[previewIndex];
                var imageUrl = '${contextPath}/' + currentBanner.imagePath;

                // Create preview with actual image
                previewContainer.innerHTML = '' +
                        '<div class="banner-preview-slide active w-full h-full relative">' +
                        '<img src="' + imageUrl + '" class="w-full h-full object-cover" ' +
                        'onerror="this.style.display=\'none\'; this.nextElementSibling.style.display=\'flex\';">' +
                        '<div class="w-full h-full bg-gradient-to-r from-[#2F5D50] to-[#57A677] flex items-center justify-center absolute inset-0" style="display: none;">' +
                        '<div class="text-center text-white p-6">' +
                        '<h3 class="text-2xl font-bold mb-2">' + currentBanner.caption + '</h3>' +
                        '<p class="opacity-90">' + currentBanner.title + '</p>' +
                        '</div>' +
                        '</div>' +
                        '</div>';

                // Update dots
                dotsContainer.innerHTML = '';
                for (var i = 0; i < banners.length; i++) {
                    var dot = document.createElement('span');
                    dot.className = 'w-3 h-3 rounded-full cursor-pointer preview-dot ' + (i === previewIndex ? 'bg-white' : 'bg-white opacity-50');
                    dot.addEventListener('click', (function (index) {
                        return function () {
                            previewIndex = index;
                            updatePreview();
                        };
                    })(i));
                    dotsContainer.appendChild(dot);
                }
            }

            // Auto rotate preview
            function startPreviewRotation() {
                if (banners.length > 1) {
                    clearInterval(previewInterval);
                    previewInterval = setInterval(function () {
                        previewIndex = (previewIndex + 1) % banners.length;
                        updatePreview();
                    }, 5000); // 5 seconds
                }
            }

            // Preview button click
            document.querySelectorAll('.preview-btn').forEach(function (button) {
                button.addEventListener('click', function () {
                    var bannerId = this.getAttribute('data-id');
                    var bannerIndex = banners.findIndex(function (b) {
                        return b.id == bannerId;
                    });

                    if (bannerIndex !== -1) {
                        previewIndex = bannerIndex;
                        updatePreview();
                    }
                });
            });

            // Initialize preview
            updatePreview();
            startPreviewRotation();

            // Debug logging
            console.log('=== MANAGE BANNER DEBUG ===');
            console.log('Total banners in page:', banners.length);
            console.log('Banners data:', banners);
            console.log('Context path:', '${contextPath}');
            console.log('Banner items in DOM:', document.querySelectorAll('.banner-item').length);
            console.log('===========================');

            // Save settings functionality
            document.getElementById('saveSettingsBtn').addEventListener('click', function () {
                var transitionSpeed = document.getElementById('transitionSpeed').value;
                var animationType = document.getElementById('animationType').value;
                var autoPlay = document.getElementById('autoPlay').checked;
                var showArrows = document.getElementById('showArrows').checked;
                var showDots = document.getElementById('showDots').checked;

                // Update preview interval based on settings
                clearInterval(previewInterval);
                if (autoPlay && banners.length > 1) {
                    previewInterval = setInterval(function () {
                        previewIndex = (previewIndex + 1) % banners.length;
                        updatePreview();
                    }, parseInt(transitionSpeed));
                }

                // Show success message
                var button = this;
                var originalText = button.textContent;
                button.textContent = 'Saving...';
                button.disabled = true;

                setTimeout(function () {
                    button.textContent = 'Saved!';
                    setTimeout(function () {
                        button.textContent = originalText;
                        button.disabled = false;
                    }, 1000);
                }, 500);
            });
        </script>

    </body>
</html>