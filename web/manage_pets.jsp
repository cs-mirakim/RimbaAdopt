<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
<%@ page import="java.util.List" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%
    // Check if user is logged in and is shelter - FIX: Added return statements
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return; // CRITICAL FIX: Stop execution after redirect
    }

    if (!SessionUtil.isShelter(session)) {
        response.sendRedirect("index.jsp");
        return; // CRITICAL FIX: Stop execution after redirect
    }

    // ===== FIX: Load pets data directly in JSP if not already set =====
    List<Pets> petsList = null;
    if (request.getAttribute("pets") == null) {
        try {
            int userId = SessionUtil.getUserId(session);
            int shelterId = userId; // shelter_id = user_id

            PetsDAO petsDAO = new PetsDAO();
            petsList = petsDAO.getPetsByShelter(shelterId);
            request.setAttribute("pets", petsList);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to load pets data: " + e.getMessage());
        }
    } else {
        petsList = (List<Pets>) request.getAttribute("pets");
    }

    // Calculate filter counts
    int maleCount = 0;
    int femaleCount = 0;
    int smallCount = 0;
    int mediumCount = 0;
    int largeCount = 0;
    int age0_1 = 0;
    int age1_3 = 0;
    int age3_5 = 0;
    int age5plus = 0;
    int availableCount = 0;
    int adoptedCount = 0;

    if (petsList != null) {
        for (Pets pet : petsList) {
            // Gender counts
            if ("male".equals(pet.getGender())) {
                maleCount++;
            }
            if ("female".equals(pet.getGender())) {
                femaleCount++;
            }

            // Size counts
            if ("small".equals(pet.getSize())) {
                smallCount++;
            }
            if ("medium".equals(pet.getSize())) {
                mediumCount++;
            }
            if ("large".equals(pet.getSize())) {
                largeCount++;
            }

            // Age counts
            if (pet.getAge() != null) {
                int age = pet.getAge();
                if (age >= 0 && age <= 1) {
                    age0_1++;
                }
                if (age > 1 && age <= 3) {
                    age1_3++;
                }
                if (age > 3 && age <= 5) {
                    age3_5++;
                }
                if (age > 5) {
                    age5plus++;
                }
            }

            // Adoption status counts - NEW
            if ("available".equalsIgnoreCase(pet.getAdoptionStatus())) {
                availableCount++;
            }
            if ("adopted".equalsIgnoreCase(pet.getAdoptionStatus())) {
                adoptedCount++;
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Manage Pets - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
        <style>
            /* Custom utility classes based on your theme */
            .text-main { color: #2B2B2B; }
            .bg-primary { background-color: #2F5D50; }
            .hover-bg-primary-dark { background-color: #24483E; }
            .text-white-on-dark { color: #FFFFFF; }
            .border-divider { border-color: #E5E5E5; }

            /* Chip Styles */
            .chip-male { background-color: #A8E6CF; color: #2B2B2B; }
            .chip-female { background-color: #F8BBD0; color: #2B2B2B; }
            .chip-small { background-color: #BBDEFB; color: #2B2B2B; }
            .chip-medium { background-color: #C8E6C9; color: #2B2B2B; }
            .chip-large { background-color: #FFECB3; color: #2B2B2B; }

            /* Adoption Status Chip Styles - NEW */
            .chip-available { background-color: #d1fae5; color: #065f46; border: 1px solid #10b981; }
            .chip-adopted { background-color: #dbeafe; color: #1e40af; border: 1px solid #3b82f6; }

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

            /* Fixed width for action buttons */
            .action-button {
                min-width: 40px;
                padding: 0.4rem 0.6rem;
                text-align: center;
            }

            /* Active filter styles */
            .active-filter {
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            }

            @keyframes slideIn {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            .animate-slideIn {
                animation: slideIn 0.3s ease-out;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7] text-main">
        <jsp:include page="includes/header.jsp" />

        <!-- Success/Error Messages -->
        <c:if test="${not empty sessionScope.success}">
            <div class="fixed top-4 right-4 z-50 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded-lg shadow-lg animate-slideIn">
                <div class="flex items-center">
                    <i class="fas fa-check-circle mr-2"></i>
                    <span>${sessionScope.success}</span>
                </div>
            </div>
            <c:remove var="success" scope="session"/>
        </c:if>

        <c:if test="${not empty sessionScope.error}">
            <div class="fixed top-4 right-4 z-50 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg shadow-lg animate-slideIn">
                <div class="flex items-center">
                    <i class="fas fa-exclamation-circle mr-2"></i>
                    <span>${sessionScope.error}</span>
                </div>
            </div>
            <c:remove var="error" scope="session"/>
        </c:if>

        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2" style="background-color: #F6F3E7;">
            <div class="w-full bg-white py-8 px-6 rounded-3xl shadow-xl border" style="max-width: 1450px; border-color: #E5E5E5;">
                <div class="mb-8 flex justify-between items-center">
                    <div>
                        <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Manage Pets</h1>
                        <p class="mt-2 text-lg" style="color: #2B2B2B;">Add, edit, and manage your shelter pets here.</p>
                    </div>
                    <button onclick="openCreateModal()" class="px-6 py-3 rounded-xl text-white font-semibold hover:bg-[#24483E] transition duration-150 shadow-lg flex items-center space-x-2" style="background-color: #2F5D50;">
                        <i class="fas fa-plus"></i>
                        <span>Add New Pet</span>
                    </button>
                </div>
                <hr style="border-top: 1px solid #E5E5E5; margin-bottom: 1.5rem; margin-top: 1.5rem;" />

                <!-- Stats Cards for Adoption Status -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                    <div class="bg-green-50 border border-green-200 rounded-xl p-4">
                        <div class="flex justify-between items-center">
                            <div>
                                <h3 class="text-lg font-semibold text-green-800">Available</h3>
                                <p class="text-3xl font-bold text-green-900"><%= availableCount%></p>
                            </div>
                            <div class="bg-green-100 p-3 rounded-lg">
                                <i class="fas fa-paw text-green-600 text-2xl"></i>
                            </div>
                        </div>
                    </div>

                    <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
                        <div class="flex justify-between items-center">
                            <div>
                                <h3 class="text-lg font-semibold text-blue-800">Adopted</h3>
                                <p class="text-3xl font-bold text-blue-900"><%= adoptedCount%></p>
                            </div>
                            <div class="bg-blue-100 p-3 rounded-lg">
                                <i class="fas fa-home text-blue-600 text-2xl"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Search and Filters Section -->
                <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 space-y-4 md:space-y-0">
                    <!-- Filters -->
                    <div class="flex flex-wrap gap-2 text-sm font-medium">
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary active-filter" 
                                data-filter="all" onclick="applyFilter('all')">
                            All Pets (${not empty pets ? pets.size() : 0})
                        </button>

                        <!-- Adoption Status Filters - NEW -->
                        <button class="px-5 py-2 rounded-full border hover:bg-green-50 transition duration-150 filter-btn chip-available"
                                data-filter="status-available" onclick="applyFilter('status-available')">
                            Available (<%= availableCount%>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-blue-50 transition duration-150 filter-btn chip-adopted"
                                data-filter="status-adopted" onclick="applyFilter('status-adopted')">
                            Adopted (<%= adoptedCount%>)
                        </button>

                        <div class="h1 border-l border-gray-300 mx-2"></div>

                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#A8E6CF] text-[#2B2B2B]"
                                data-filter="gender-male" onclick="applyFilter('gender-male')">
                            ♂ Male (<%= maleCount%>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#F8BBD0] text-[#2B2B2B]"
                                data-filter="gender-female" onclick="applyFilter('gender-female')">
                            ♀ Female (<%= femaleCount%>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#BBDEFB] text-[#2B2B2B]"
                                data-filter="size-small" onclick="applyFilter('size-small')">
                            Small (<%= smallCount%>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#C8E6C9] text-[#2B2B2B]"
                                data-filter="size-medium" onclick="applyFilter('size-medium')">
                            Medium (<%= mediumCount%>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFECB3] text-[#2B2B2B]"
                                data-filter="size-large" onclick="applyFilter('size-large')">
                            Large (<%= largeCount%>)
                        </button>
                    </div>

                    <!-- Search Box -->
                    <div class="relative w-full md:w-80">
                        <form id="searchForm" action="manage-pets" method="GET" class="flex items-center">
                            <input type="text" name="search" id="searchInput" 
                                   value="${param.search}" 
                                   placeholder="Search by name or species..." 
                                   class="w-full py-2.5 pl-10 pr-4 border rounded-xl transition duration-150 shadow-sm text-base custom-focus" 
                                   style="border-color: #E5E5E5; color: #2B2B2B;">
                            <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                            <input type="submit" class="hidden" />
                        </form>
                    </div>
                </div>

                <!-- Age Filter -->
                <div class="mb-6">
                    <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Age Filter:</label>
                    <div class="flex flex-wrap gap-2">
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50] active-filter"
                                data-age="all" onclick="applyAgeFilter('all')">
                            All Ages
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="0-1" onclick="applyAgeFilter('0-1')">
                            0-1 year (<%= age0_1%>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="1-3" onclick="applyAgeFilter('1-3')">
                            1-3 years (<%= age1_3%>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="3-5" onclick="applyAgeFilter('3-5')">
                            3-5 years (<%= age3_5%>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="5+" onclick="applyAgeFilter('5+')">
                            5+ years (<%= age5plus%>)
                        </button>
                    </div>
                </div>

                <!-- Pets Table -->
                <div class="overflow-x-auto rounded-xl border shadow-lg" style="border-color: #E5E5E5;">
                    <table class="min-w-full divide-y" style="border-color: #E5E5E5;">
                        <thead style="background-color: #F6F3E7;">
                            <tr>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 5%;">ID</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 8%;">Picture</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Name</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Species</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Breed</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 7%;">Age</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 8%;">Gender</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 8%;">Size</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 12%;">Adoption Status</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Color</th>
                                <th class="px-6 py-4 text-left text-xs font-bold uppercase tracking-wider" style="color: #2F5D50;">Health Status</th>
                                <th class="px-6 py-4 text-center text-xs font-bold uppercase tracking-wider" style="color: #2F5D50; width: 12%;">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="petsTableBody" class="bg-white divide-y" style="border-color: #E5E5E5;">
                            <c:choose>
                                <c:when test="${not empty pets}">
                                    <c:forEach var="pet" items="${pets}">
                                        <tr class="pet-row hover:bg-gray-50 transition duration-100"
                                            data-gender="${pet.gender}"
                                            data-size="${pet.size}"
                                            data-age="${pet.age != null ? pet.age : ''}"
                                            data-status="${pet.adoptionStatus}">
                                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;">${pet.petId}</td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <div class="flex-shrink-0 h-12 w-12">
                                                    <img class="h-12 w-12 rounded-full object-cover border" 
                                                         src="${not empty pet.photoPath ? pet.photoPath : 'https://via.placeholder.com/48x48?text=Pet'}" 
                                                         alt="${pet.name}" 
                                                         onerror="this.src='https://via.placeholder.com/48x48?text=Pet'"
                                                         style="border-color: #E5E5E5;">
                                                </div>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <div class="text-sm font-bold pet-name" style="color: #2B2B2B;">${pet.name}</div>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm pet-species" style="color: #2B2B2B;">${pet.species}</td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">${not empty pet.breed ? pet.breed : '-'}</td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium" style="color: #2B2B2B;">${pet.age != null ? pet.age : '-'} ${pet.age != null ? 'yrs' : ''}</td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${pet.gender == 'male' ? 'chip-male' : 'chip-female'}">
                                                    ${pet.gender == 'male' ? '♂ Male' : '♀ Female'}
                                                </span>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full 
                                                      ${pet.size == 'small' ? 'chip-small' : pet.size == 'medium' ? 'chip-medium' : 'chip-large'}">
                                                    ${pet.size}
                                                </span>
                                            </td>
                                            <!-- Adoption Status Column -->
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <span class="px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full 
                                                      ${pet.adoptionStatus == 'available' ? 'chip-available' : 'chip-adopted'}">
                                                    <c:choose>
                                                        <c:when test="${pet.adoptionStatus == 'available'}">
                                                            <i class="fas fa-paw mr-1"></i> Available
                                                        </c:when>
                                                        <c:when test="${pet.adoptionStatus == 'adopted'}">
                                                            <i class="fas fa-home mr-1"></i> Adopted
                                                        </c:when>
                                                    </c:choose>
                                                </span>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">${not empty pet.color ? pet.color : '-'}</td>
                                            <td class="px-6 py-4 text-sm" style="color: #2B2B2B;">${not empty pet.healthStatus ? pet.healthStatus : '-'}</td>
                                            <td class="px-6 py-4 whitespace-nowrap text-center">
                                                <div class="flex justify-center space-x-2">
                                                    <button onclick="openEditModal(${pet.petId}, '${pet.name}', '${pet.species}', '${pet.breed}', ${pet.age != null ? pet.age : 'null'}, '${pet.gender}', '${pet.size}', '${pet.color}', '${pet.healthStatus}', '${pet.description}', '${pet.photoPath}', '${pet.adoptionStatus}')" 
                                                            class="action-button px-3 py-2 rounded-lg font-semibold text-white hover:bg-[#24483E]" 
                                                            style="background-color: #2F5D50;" title="Edit">
                                                        <i class="fas fa-edit"></i>
                                                    </button>
                                                    <button onclick="openDeleteModal(${pet.petId}, '${pet.name}')" 
                                                            class="action-button px-3 py-2 rounded-lg font-semibold text-white hover:bg-red-700" 
                                                            style="background-color: #B84A4A;" title="Delete">
                                                        <i class="fas fa-trash"></i>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <tr>
                                        <td colspan="12" class="px-6 py-8 text-center text-gray-500">
                                            <i class="fas fa-paw text-4xl mb-2"></i>
                                            <p class="text-lg">No pets found. Add your first pet!</p>
                                        </td>
                                    </tr>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>

                <!-- Pet Count -->
                <div class="text-sm mt-4" style="color: #2B2B2B;">
                    Total Pets: <span id="totalPetsCount" class="font-semibold">${not empty pets ? pets.size() : 0}</span>
                    <span class="ml-4">
                        <span class="chip-available px-2 py-1 rounded-full text-xs">Available: <%= availableCount%></span>
                        <span class="chip-adopted px-2 py-1 rounded-full text-xs ml-2">Adopted: <%= adoptedCount%></span>
                    </span>
                    <span id="filteredCount" class="text-gray-600 ml-2 hidden"></span>
                </div>
            </div>
        </main>

        <!-- Create/Edit Modal -->
        <div id="createModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-2xl mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #2F5D50;" id="modalTitle">Add New Pet</h3>
                    <button onclick="closeModal('createModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="max-h-[70vh] overflow-y-auto pr-2">
                    <form id="petForm" action="manage-pets" method="POST" enctype="multipart/form-data" class="space-y-4">
                        <input type="hidden" name="action" id="formAction" value="create">
                        <input type="hidden" name="petId" id="formPetId" value="">
                        <input type="hidden" name="existingPhotoPath" id="formExistingPhotoPath" value="">

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label for="petName" class="block text-sm font-medium" style="color: #2B2B2B;">Pet Name: <span class="text-red-500">*</span></label>
                                <input type="text" id="petName" name="petName" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Enter pet's name">
                            </div>
                            <div>
                                <label for="species" class="block text-sm font-medium" style="color: #2B2B2B;">Species: <span class="text-red-500">*</span></label>
                                <select id="species" name="species" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                                    <option value="">Select species</option>
                                    <option value="Dog">Dog</option>
                                    <option value="Cat">Cat</option>
                                    <option value="Rabbit">Rabbit</option>
                                    <option value="Bird">Bird</option>
                                    <option value="Other">Other</option>
                                </select>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label for="breed" class="block text-sm font-medium" style="color: #2B2B2B;">Breed: (Optional)</label>
                                <input type="text" id="breed" name="breed" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="E.g., Golden Retriever, Persian">
                            </div>
                            <div>
                                <label for="age" class="block text-sm font-medium" style="color: #2B2B2B;">Age (years): (Optional)</label>
                                <input type="number" id="age" name="age" min="0" max="30" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="E.g., 3">
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label for="gender" class="block text-sm font-medium" style="color: #2B2B2B;">Gender: <span class="text-red-500">*</span></label>
                                <select id="gender" name="gender" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                                    <option value="">Select gender</option>
                                    <option value="male">Male</option>
                                    <option value="female">Female</option>
                                </select>
                            </div>
                            <div>
                                <label for="size" class="block text-sm font-medium" style="color: #2B2B2B;">Size: <span class="text-red-500">*</span></label>
                                <select id="size" name="size" required class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;">
                                    <option value="">Select size</option>
                                    <option value="small">Small</option>
                                    <option value="medium">Medium</option>
                                    <option value="large">Large</option>
                                </select>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label for="color" class="block text-sm font-medium" style="color: #2B2B2B;">Color: (Optional)</label>
                                <input type="text" id="color" name="color" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="E.g., Golden, Black and White">
                            </div>
                            <div>
                                <label for="healthStatus" class="block text-sm font-medium" style="color: #2B2B2B;">Health Status: (Optional)</label>
                                <input type="text" id="healthStatus" name="healthStatus" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="E.g., Vaccinated, Dewormed">
                            </div>
                        </div>

                        <!-- Adoption Status Field -->
                        <div>
                            <label for="adoptionStatus" class="block text-sm font-medium" style="color: #2B2B2B;">Adoption Status: <span class="text-red-500">*</span></label>
                            <div class="mt-2 space-x-4">
                                <label class="inline-flex items-center">
                                    <input type="radio" name="adoptionStatus" value="available" id="statusAvailable" checked class="h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300">
                                    <span class="ml-2 chip-available px-3 py-1 rounded-full">Available</span>
                                </label>
                                <label class="inline-flex items-center">
                                    <input type="radio" name="adoptionStatus" value="adopted" id="statusAdopted" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300">
                                    <span class="ml-2 chip-adopted px-3 py-1 rounded-full">Adopted</span>
                                </label>
                            </div>
                        </div>

                        <div>
                            <label for="description" class="block text-sm font-medium" style="color: #2B2B2B;">Description: (Optional)</label>
                            <textarea id="description" name="description" rows="3" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Describe the pet's personality, behavior, special needs, etc."></textarea>
                        </div>

                        <!-- Pet Photo Section -->
                        <div>
                            <label for="petPhoto" class="block text-sm font-medium" style="color: #2B2B2B;">Pet Photo:</label>
                            <div class="mt-2 flex items-center space-x-4">
                                <div class="flex-1">
                                    <input type="file" id="petPhoto" name="petPhoto" accept="image/*" 
                                           class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 
                                           file:rounded-lg file:border-0 file:text-sm file:font-semibold
                                           file:bg-[#2F5D50] file:text-white hover:file:bg-[#24483E]
                                           transition duration-150">
                                    <p class="text-xs text-gray-500 mt-1">Upload a new photo (JPG, PNG, GIF) - Max 5MB</p>

                                    <!-- Checkbox untuk remove existing photo -->
                                    <div id="removePhotoContainer" class="hidden mt-2">
                                        <label class="inline-flex items-center">
                                            <input type="checkbox" name="removePhoto" value="true" 
                                                   class="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded">
                                            <span class="ml-2 text-sm text-red-600">Remove current photo</span>
                                        </label>
                                        <p class="text-xs text-gray-500">Current photo will be deleted and replaced with default</p>
                                    </div>
                                </div>
                                <div id="imagePreview" class="hidden flex-shrink-0">
                                    <img id="previewImage" class="h-20 w-20 object-cover rounded-lg border" 
                                         style="border-color: #E5E5E5;" src="" alt="Preview">
                                </div>
                            </div>
                        </div>

                        <div class="flex justify-end pt-4 space-x-3">
                            <button type="button" onclick="closeModal('createModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                                Cancel
                            </button>
                            <button type="submit" class="px-6 py-2 rounded-xl text-white font-medium hover:bg-[#24483E] transition duration-150 shadow-md" style="background-color: #2F5D50;">
                                Save Pet
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div id="deleteModal" class="modal fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50 hidden opacity-0 transition-opacity duration-300">
            <div class="bg-white rounded-2xl p-8 w-full max-w-md mx-4 shadow-2xl transform transition-transform duration-300 scale-95" role="dialog" aria-modal="true" style="color: #2B2B2B;">
                <div class="flex justify-between items-center border-b pb-3 mb-4" style="border-color: #E5E5E5;">
                    <h3 class="text-2xl font-bold" style="color: #B84A4A;">Delete Pet</h3>
                    <button onclick="closeModal('deleteModal')" class="text-gray-400 hover:text-gray-600">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>
                <div class="text-gray-700">
                    <p class="mb-4 text-lg" style="color: #2B2B2B;">Are you sure you want to delete <strong id="deletePetName" style="color: #2B2B2B;"></strong>?</p>
                    <p class="mb-6 text-sm italic text-white font-medium p-3 rounded-lg border" style="background-color: #B84A4A; border-color: #B84A4A; color: #FFFFFF;">
                        ⚠️ This action cannot be undone. All information about this pet will be permanently deleted.
                    </p>
                </div>
                <div class="flex justify-end space-x-3 pt-4">
                    <button onclick="closeModal('deleteModal')" class="px-5 py-2 rounded-xl border text-[#2B2B2B] hover:bg-gray-100 transition duration-150 font-medium" style="border-color: #E5E5E5;">
                        Cancel
                    </button>
                    <form id="deleteForm" action="manage-pets" method="POST" style="display: inline;">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="petId" id="deletePetId" value="">
                        <button type="submit" class="px-5 py-2 rounded-xl text-white font-semibold hover:bg-red-700 transition duration-200 shadow-md" style="background-color: #B84A4A;">
                            Yes, Delete
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <jsp:include page="includes/footer.jsp" />
        <jsp:include page="includes/sidebar.jsp" />
        <script src="includes/sidebar.js"></script>

        <script>
                        // =======================================================
                        // CONFIGURATION AND TRACKING
                        // =======================================================
                        let currentFilter = 'all';
                        let currentAgeFilter = 'all';
                        let currentSearchTerm = '';
                        let activeAjaxRequests = 0;

                        // Debug mode
                        const DEBUG = false;

                        // =======================================================
                        // 1. IMAGE LOADING HANDLER (PENTING UNTUK STOP LOADING ICON)
                        // =======================================================
                        function handleAllImagesLoaded() {
                            return new Promise(function (resolve) {
                                const images = document.querySelectorAll('img');
                                const totalImages = images.length;
                                let loadedCount = 0;

                                if (DEBUG)
                                    console.log(`Checking ${totalImages} images...`);

                                if (totalImages === 0) {
                                    resolve();
                                    return;
                                }

                                // Function to track each image
                                function imageLoaded() {
                                    loadedCount++;
                                    this.removeEventListener('load', imageLoaded);
                                    this.removeEventListener('error', imageLoaded);

                                    if (DEBUG && loadedCount % 5 === 0) {
                                        console.log(`Images loaded: ${loadedCount}/${totalImages}`);
                                    }

                                    if (loadedCount === totalImages) {
                                        clearTimeout(timeoutId);
                                        if (DEBUG)
                                            console.log('All images loaded successfully');
                                        resolve();
                                    }
                                }

                                // Check each image
                                images.forEach(img => {
                                    if (img.complete) {
                                        loadedCount++;
                                    } else {
                                        img.addEventListener('load', imageLoaded);
                                        img.addEventListener('error', imageLoaded);
                                    }
                                });

                                // Check if all already loaded
                                if (loadedCount === totalImages) {
                                    if (DEBUG)
                                        console.log('All images already loaded from cache');
                                    resolve();
                                    return;
                                }

                                // Fallback timeout (3 seconds)
                                const timeoutId = setTimeout(() => {
                                    if (DEBUG)
                                        console.warn(`Image loading timeout. Loaded: ${loadedCount}/${totalImages}`);
                                    resolve();
                                }, 3000);
                            });
                        }

                        // =======================================================
                        // 2. FORCE STOP LOADING INDICATOR (UTAMA!)
                        // =======================================================
                        function forceStopLoadingIndicator() {
                            try {
                                console.log('Force stopping browser loading indicator...');

                                // Method 1: window.stop() - stops all pending requests
                                if (window.stop && typeof window.stop === 'function') {
                                    window.stop();
                                }

                                // Method 2: Mark page as fully loaded
                                document.documentElement.setAttribute('data-page-loaded', 'true');
                                document.body.classList.add('page-loaded');

                                // Method 3: Stop any pending animations
                                const animations = document.querySelectorAll('.animate-slideIn');
                                animations.forEach(el => {
                                    el.style.animation = 'none';
                                });

                                console.log('Loading indicator stopped successfully');
                            } catch (e) {
                                console.warn('Error stopping loading indicator:', e);
                            }
                        }

                        // =======================================================
                        // 3. FILTER FUNCTIONS (CLIENT-SIDE)
                        // =======================================================
                        function applyFilter(filterType) {
                            currentFilter = filterType;

                            // Update button styles
                            document.querySelectorAll('.filter-btn').forEach(btn => {
                                btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter',
                                        'chip-male', 'chip-female', 'chip-small', 'chip-medium', 'chip-large',
                                        'chip-available', 'chip-adopted');
                                btn.classList.add('border', 'text-[#2B2B2B]', 'hover:bg-[#F6F3E7]');

                                if (btn.getAttribute('data-filter') === filterType) {
                                    btn.classList.remove('border', 'text-[#2B2B2B]', 'hover:bg-[#F6F3E7]');
                                    btn.classList.add('active-filter');

                                    if (filterType === 'all') {
                                        btn.classList.add('bg-primary', 'text-white', 'shadow-md');
                                    } else if (filterType === 'gender-male') {
                                        btn.classList.add('chip-male', 'shadow-md');
                                    } else if (filterType === 'gender-female') {
                                        btn.classList.add('chip-female', 'shadow-md');
                                    } else if (filterType === 'size-small') {
                                        btn.classList.add('chip-small', 'shadow-md');
                                    } else if (filterType === 'size-medium') {
                                        btn.classList.add('chip-medium', 'shadow-md');
                                    } else if (filterType === 'size-large') {
                                        btn.classList.add('chip-large', 'shadow-md');
                                    } else if (filterType === 'status-available') {
                                        btn.classList.add('chip-available', 'shadow-md');
                                    } else if (filterType === 'status-adopted') {
                                        btn.classList.add('chip-adopted', 'shadow-md');
                                    }
                                }
                            });

                            filterAndDisplayPets();
                        }

                        function applyAgeFilter(ageFilter) {
                            currentAgeFilter = ageFilter;

                            // Update button styles
                            document.querySelectorAll('.age-filter-btn').forEach(btn => {
                                btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                btn.classList.add('border-[#2F5D50]', 'text-[#2F5D50]', 'hover:bg-[#F6F3E7]');

                                if (btn.getAttribute('data-age') === ageFilter) {
                                    btn.classList.remove('border-[#2F5D50]', 'text-[#2F5D50]');
                                    btn.classList.add('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                }
                            });

                            filterAndDisplayPets();
                        }

                        function filterAndDisplayPets() {
                            const rows = document.querySelectorAll('.pet-row');
                            let visibleCount = 0;

                            rows.forEach(row => {
                                let showRow = true;

                                // Apply gender/size/status filter
                                if (currentFilter !== 'all') {
                                    if (currentFilter.startsWith('gender-')) {
                                        const gender = currentFilter.split('-')[1];
                                        if (row.getAttribute('data-gender') !== gender) {
                                            showRow = false;
                                        }
                                    } else if (currentFilter.startsWith('size-')) {
                                        const size = currentFilter.split('-')[1];
                                        if (row.getAttribute('data-size') !== size) {
                                            showRow = false;
                                        }
                                    } else if (currentFilter.startsWith('status-')) {
                                        const status = currentFilter.split('-')[1];
                                        if (row.getAttribute('data-status') !== status) {
                                            showRow = false;
                                        }
                                    }
                                }

                                // Apply age filter
                                if (showRow && currentAgeFilter !== 'all') {
                                    const ageAttr = row.getAttribute('data-age');
                                    if (ageAttr) {
                                        const age = parseInt(ageAttr);
                                        switch (currentAgeFilter) {
                                            case '0-1':
                                                if (age < 0 || age > 1)
                                                    showRow = false;
                                                break;
                                            case '1-3':
                                                if (age <= 1 || age > 3)
                                                    showRow = false;
                                                break;
                                            case '3-5':
                                                if (age <= 3 || age > 5)
                                                    showRow = false;
                                                break;
                                            case '5+':
                                                if (age <= 5)
                                                    showRow = false;
                                                break;
                                        }
                                    } else {
                                        // If pet has no age and filter is not 'all', hide it
                                        showRow = false;
                                    }
                                }

                                // Apply search filter
                                if (showRow && currentSearchTerm) {
                                    const petName = row.querySelector('.pet-name').textContent.toLowerCase();
                                    const species = row.querySelector('.pet-species').textContent.toLowerCase();

                                    if (!petName.includes(currentSearchTerm) && !species.includes(currentSearchTerm)) {
                                        showRow = false;
                                    }
                                }

                                // Show/hide row
                                if (showRow) {
                                    row.style.display = '';
                                    visibleCount++;
                                } else {
                                    row.style.display = 'none';
                                }
                            });

                            // Update counter display
                            const totalCount = rows.length;
                            const filteredCountSpan = document.getElementById('filteredCount');

                            if (currentFilter !== 'all' || currentAgeFilter !== 'all' || currentSearchTerm) {
                                filteredCountSpan.textContent = `(Filtered: ${visibleCount})`;
                                filteredCountSpan.classList.remove('hidden');
                            } else {
                                filteredCountSpan.classList.add('hidden');
                            }

                            // Show message if no pets match filter
                            const noPetsRow = document.querySelector('tbody tr:not(.pet-row)');
                            if (visibleCount === 0 && rows.length > 0) {
                                if (!noPetsRow) {
                                    const tableBody = document.getElementById('petsTableBody');
                                    const messageRow = document.createElement('tr');
                                    messageRow.innerHTML = `
                    <td colspan="12" class="px-6 py-8 text-center text-gray-500">
                        <i class="fas fa-filter text-4xl mb-2"></i>
                        <p class="text-lg">No pets match the current filters.</p>
                        <button onclick="clearAllFilters()" class="mt-2 px-4 py-2 text-sm rounded-xl border border-[#2F5D50] text-[#2F5D50] hover:bg-[#F6F3E7] transition duration-150">
                            Clear Filters
                        </button>
                    </td>
                `;
                                    tableBody.appendChild(messageRow);
                                }
                            } else if (noPetsRow) {
                                noPetsRow.remove();
                            }
                        }

                        function clearAllFilters() {
                            // Reset all filters
                            currentFilter = 'all';
                            currentAgeFilter = 'all';
                            currentSearchTerm = '';

                            // Reset search input
                            const searchInput = document.getElementById('searchInput');
                            if (searchInput) {
                                searchInput.value = '';
                            }

                            // Reset button styles
                            document.querySelectorAll('.filter-btn').forEach(btn => {
                                btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter',
                                        'chip-male', 'chip-female', 'chip-small', 'chip-medium', 'chip-large',
                                        'chip-available', 'chip-adopted');
                                btn.classList.add('border', 'text-[#2B2B2B]', 'hover:bg-[#F6F3E7]');

                                if (btn.getAttribute('data-filter') === 'all') {
                                    btn.classList.remove('border', 'text-[#2B2B2B]', 'hover:bg-[#F6F3E7]');
                                    btn.classList.add('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                }
                            });

                            document.querySelectorAll('.age-filter-btn').forEach(btn => {
                                btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                btn.classList.add('border-[#2F5D50]', 'text-[#2F5D50]', 'hover:bg-[#F6F3E7]');

                                if (btn.getAttribute('data-age') === 'all') {
                                    btn.classList.remove('border-[#2F5D50]', 'text-[#2F5D50]');
                                    btn.classList.add('bg-primary', 'text-white', 'shadow-md', 'active-filter');
                                }
                            });

                            // Show all pets
                            filterAndDisplayPets();
                        }

                        // =======================================================
                        // 4. MODAL FUNCTIONS
                        // =======================================================

                        // Image preview function
                        function previewImage(event) {
                            const input = event.target;
                            const previewContainer = document.getElementById('imagePreview');
                            const previewImage = document.getElementById('previewImage');

                            if (input.files && input.files[0]) {
                                // Validate file size (max 5MB)
                                const fileSize = input.files[0].size / 1024 / 1024; // in MB
                                if (fileSize > 5) {
                                    alert('File size exceeds 5MB limit. Please choose a smaller file.');
                                    input.value = '';
                                    previewContainer.classList.add('hidden');
                                    return;
                                }

                                const reader = new FileReader();

                                reader.onload = function (e) {
                                    previewImage.src = e.target.result;
                                    previewContainer.classList.remove('hidden');
                                }

                                reader.onerror = function () {
                                    console.error('Error reading image file');
                                    previewContainer.classList.add('hidden');
                                }

                                reader.readAsDataURL(input.files[0]);
                            } else {
                                previewContainer.classList.add('hidden');
                                previewImage.src = '';
                            }
                        }

                        // Open Create Modal (for adding new pet)
                        function openCreateModal() {
                            document.getElementById('modalTitle').textContent = 'Add New Pet';
                            document.getElementById('formAction').value = 'create';
                            document.getElementById('formPetId').value = '';
                            document.getElementById('formExistingPhotoPath').value = '';
                            document.getElementById('petForm').reset();
                            document.getElementById('imagePreview').classList.add('hidden');
                            document.getElementById('previewImage').src = '';
                            document.getElementById('petPhoto').value = '';
                            document.getElementById('statusAvailable').checked = true;
                            document.getElementById('removePhotoContainer').classList.add('hidden');

                            openModal('createModal');
                        }

                        // Open Edit Modal
                        function openEditModal(petId, name, species, breed, age, gender, size, color, healthStatus, description, photoPath, adoptionStatus) {
                            document.getElementById('modalTitle').textContent = 'Edit Pet Details';
                            document.getElementById('formAction').value = 'update';
                            document.getElementById('formPetId').value = petId;
                            document.getElementById('formExistingPhotoPath').value = photoPath || '';
                            document.getElementById('petName').value = name;
                            document.getElementById('species').value = species;
                            document.getElementById('breed').value = breed || '';
                            document.getElementById('age').value = age !== 'null' ? age : '';
                            document.getElementById('gender').value = gender;
                            document.getElementById('size').value = size;
                            document.getElementById('color').value = color || '';
                            document.getElementById('healthStatus').value = healthStatus || '';
                            document.getElementById('description').value = description || '';

                            // Set adoption status
                            if (adoptionStatus === 'available') {
                                document.getElementById('statusAvailable').checked = true;
                            } else if (adoptionStatus === 'adopted') {
                                document.getElementById('statusAdopted').checked = true;
                            }

                            // Handle existing photo
                            const removePhotoContainer = document.getElementById('removePhotoContainer');
                            if (photoPath && photoPath !== 'null' && !photoPath.includes('default.png')) {
                                const previewContainer = document.getElementById('imagePreview');
                                const previewImage = document.getElementById('previewImage');

                                // Set image with onload/onerror handling
                                previewImage.onload = function () {
                                    previewContainer.classList.remove('hidden');
                                };
                                previewImage.onerror = function () {
                                    console.warn('Failed to load existing image:', photoPath);
                                    previewContainer.classList.add('hidden');
                                };
                                previewImage.src = photoPath;

                                // Show remove photo option
                                removePhotoContainer.classList.remove('hidden');
                            } else {
                                document.getElementById('imagePreview').classList.add('hidden');
                                // Hide remove photo option if no photo or default photo
                                removePhotoContainer.classList.add('hidden');
                            }

                            openModal('createModal');
                        }

                        // Open Delete Modal
                        function openDeleteModal(petId, petName) {
                            document.getElementById('deletePetName').textContent = petName;
                            document.getElementById('deletePetId').value = petId;
                            openModal('deleteModal');
                        }

                        // Generic modal open/close functions
                        function openModal(modalId) {
                            const modal = document.getElementById(modalId);
                            modal.classList.remove('hidden');
                            setTimeout(() => {
                                modal.classList.remove('opacity-0');
                                modal.querySelector('div:nth-child(1)').classList.remove('scale-95');
                            }, 10);
                        }

                        function closeModal(modalId) {
                            const modal = document.getElementById(modalId);
                            modal.classList.add('opacity-0');
                            modal.querySelector('div:nth-child(1)').classList.add('scale-95');
                            setTimeout(() => {
                                modal.classList.add('hidden');
                                if (modalId === 'createModal') {
                                    document.getElementById('petForm').reset();
                                    document.getElementById('imagePreview').classList.add('hidden');
                                    document.getElementById('previewImage').src = '';
                                    document.getElementById('removePhotoContainer').classList.add('hidden');
                                }
                            }, 300);
                        }

                        // =======================================================
                        // 5. FORM SUBMISSION HANDLING (PENTING!)
                        // =======================================================
                        function handleFormSubmission(event) {
                            // Only handle if form has file upload
                            if (event.target.id === 'petForm') {
                                const formData = new FormData(event.target);
                                const submitBtn = event.target.querySelector('button[type="submit"]');
                                const originalText = submitBtn.innerHTML;

                                // Disable button and show loading
                                submitBtn.disabled = true;
                                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Saving...';

                                // Submit normally (no AJAX) - let the form submit
                                // Button will be re-enabled on page reload
                                return true;
                            }
                            return true;
                        }

                        // =======================================================
                        // 6. INITIALIZATION AND LOADING HANDLERS (PENTING!)
                        // =======================================================

                        document.addEventListener('DOMContentLoaded', function () {
                            console.log('Manage Pets page - DOM loaded');

                            // File input preview
                            const photoInput = document.getElementById('petPhoto');
                            if (photoInput) {
                                photoInput.addEventListener('change', previewImage);
                            }

                            // Search functionality
                            const searchInput = document.getElementById('searchInput');
                            if (searchInput) {
                                // Set current search term from URL parameter
                                const urlParams = new URLSearchParams(window.location.search);
                                const searchParam = urlParams.get('search');
                                if (searchParam) {
                                    searchInput.value = searchParam;
                                    currentSearchTerm = searchParam.toLowerCase();
                                    // Apply filter immediately
                                    filterAndDisplayPets();
                                }

                                // Live search (client-side)
                                searchInput.addEventListener('input', function (e) {
                                    currentSearchTerm = e.target.value.toLowerCase().trim();
                                    filterAndDisplayPets();
                                });
                            }

                            // Form submission handler
                            const petForm = document.getElementById('petForm');
                            if (petForm) {
                                petForm.addEventListener('submit', handleFormSubmission);
                            }

                            // Auto-hide success/error messages after 5 seconds
                            setTimeout(() => {
                                const messages = document.querySelectorAll('.fixed.top-4');
                                messages.forEach(msg => {
                                    msg.style.display = 'none';
                                });
                            }, 5000);

                            // Apply initial filter if URL has filter parameter
                            const urlParams = new URLSearchParams(window.location.search);
                            const urlFilter = urlParams.get('filter');
                            const urlAgeFilter = urlParams.get('ageFilter');

                            if (urlFilter) {
                                applyFilter(urlFilter);
                            }
                            if (urlAgeFilter) {
                                applyAgeFilter(urlAgeFilter);
                            }

                            // Initial filter display
                            filterAndDisplayPets();

                            // Handle image loading
                            handleAllImagesLoaded().then(() => {
                                console.log('All pet images loaded');
                            }).catch(err => {
                                console.warn('Image loading issue:', err);
                            });
                        });

                        // =======================================================
                        // 7. WINDOW LOAD EVENT - UTAMA UNTUK STOP LOADING ICON
                        // =======================================================
                        window.addEventListener('load', function () {
                            console.log('Manage Pets page - Window fully loaded');

                            // Force stop loading indicator after 500ms
                            setTimeout(() => {
                                forceStopLoadingIndicator();

                                // Check for any issues
                                if (document.querySelectorAll('img:not([src])').length > 0) {
                                    console.warn('Some images have empty src attributes');
                                }
                            }, 500);
                        });

                        // =======================================================
                        // 8. FALLBACK TIMEOUT - JIKA WINDOW.LOAD TAK TRIGGER
                        // =======================================================
                        setTimeout(() => {
                            if (!document.documentElement.hasAttribute('data-page-loaded')) {
                                console.warn('Fallback: Forcing page load completion after 6 seconds');
                                forceStopLoadingIndicator();
                            }
                        }, 6000);

                        // =======================================================
                        // 9. ERROR HANDLING
                        // =======================================================
                        // Catch unhandled errors that might cause loading to hang
                        window.addEventListener('error', function (event) {
                            console.error('JavaScript error:', event.error);
                            // Don't prevent default, just log
                        });

                        // Catch unhandled promise rejections
                        window.addEventListener('unhandledrejection', function (event) {
                            console.error('Unhandled promise rejection:', event.reason);
                            event.preventDefault(); // Prevent browser error display
                        });
        </script>

    </body>
</html>