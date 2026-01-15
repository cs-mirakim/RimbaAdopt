<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
<%@ page import="java.util.List" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

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
    
    if (petsList != null) {
        for (Pets pet : petsList) {
            // Gender counts
            if ("male".equals(pet.getGender())) maleCount++;
            if ("female".equals(pet.getGender())) femaleCount++;
            
            // Size counts
            if ("small".equals(pet.getSize())) smallCount++;
            if ("medium".equals(pet.getSize())) mediumCount++;
            if ("large".equals(pet.getSize())) largeCount++;
            
            // Age counts
            if (pet.getAge() != null) {
                int age = pet.getAge();
                if (age >= 0 && age <= 1) age0_1++;
                if (age > 1 && age <= 3) age1_3++;
                if (age > 3 && age <= 5) age3_5++;
                if (age > 5) age5plus++;
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

            /* Status indicator */
            .status-indicator {
                display: inline-block;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                margin-right: 6px;
            }
            
            /* Active filter styles */
            .active-filter {
                box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
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

                <!-- Search and Filters Section -->
                <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 space-y-4 md:space-y-0">
                    <!-- Filters -->
                    <div class="flex flex-wrap gap-2 text-sm font-medium">
                        <button class="px-5 py-2 rounded-full text-white hover:bg-[#24483E] transition duration-150 shadow-md filter-btn bg-primary active-filter" 
                                data-filter="all" onclick="applyFilter('all')">
                            All Pets (${not empty pets ? pets.size() : 0})
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#A8E6CF] text-[#2B2B2B]"
                                data-filter="gender-male" onclick="applyFilter('gender-male')">
                            ♂ Male (<%= maleCount %>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#F8BBD0] text-[#2B2B2B]"
                                data-filter="gender-female" onclick="applyFilter('gender-female')">
                            ♀ Female (<%= femaleCount %>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#BBDEFB] text-[#2B2B2B]"
                                data-filter="size-small" onclick="applyFilter('size-small')">
                            Small (<%= smallCount %>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#C8E6C9] text-[#2B2B2B]"
                                data-filter="size-medium" onclick="applyFilter('size-medium')">
                            Medium (<%= mediumCount %>)
                        </button>
                        <button class="px-5 py-2 rounded-full border hover:bg-[#F6F3E7] transition duration-150 filter-btn border-[#FFECB3] text-[#2B2B2B]"
                                data-filter="size-large" onclick="applyFilter('size-large')">
                            Large (<%= largeCount %>)
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
                            0-1 year (<%= age0_1 %>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="1-3" onclick="applyAgeFilter('1-3')">
                            1-3 years (<%= age1_3 %>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="3-5" onclick="applyAgeFilter('3-5')">
                            3-5 years (<%= age3_5 %>)
                        </button>
                        <button class="px-4 py-2 text-sm rounded-full border hover:bg-[#F6F3E7] transition duration-150 age-filter-btn border-[#2F5D50] text-[#2F5D50]"
                                data-age="5+" onclick="applyAgeFilter('5+')">
                            5+ years (<%= age5plus %>)
                        </button>
                    </div>
                </div>

                <!-- Pets Table - USING JSTL DIRECTLY (NO JAVASCRIPT DUMMY DATA) -->
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
                                            data-age="${pet.age != null ? pet.age : ''}">
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
                                            <td class="px-6 py-4 whitespace-nowrap text-sm" style="color: #2B2B2B;">${not empty pet.color ? pet.color : '-'}</td>
                                            <td class="px-6 py-4 text-sm" style="color: #2B2B2B;">${not empty pet.healthStatus ? pet.healthStatus : '-'}</td>
                                            <td class="px-6 py-4 whitespace-nowrap text-center">
                                                <div class="flex justify-center space-x-2">
                                                    <button onclick="openEditModal(${pet.petId}, '${pet.name}', '${pet.species}', '${pet.breed}', ${pet.age != null ? pet.age : 'null'}, '${pet.gender}', '${pet.size}', '${pet.color}', '${pet.healthStatus}', '${pet.description}', '${pet.photoPath}')" 
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
                                        <td colspan="11" class="px-6 py-8 text-center text-gray-500">
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

                        <div>
                            <label for="description" class="block text-sm font-medium" style="color: #2B2B2B;">Description: (Optional)</label>
                            <textarea id="description" name="description" rows="3" class="mt-1 block w-full border rounded-lg shadow-sm p-3 transition duration-150 custom-focus" style="border-color: #E5E5E5; color: #2B2B2B;" placeholder="Describe the pet's personality, behavior, special needs, etc."></textarea>
                        </div>

                        <div>
                            <label for="petPhoto" class="block text-sm font-medium" style="color: #2B2B2B;">Pet Photo: (Optional)</label>
                            <div class="mt-2 flex items-center space-x-4">
                                <div class="flex-1">
                                    <input type="file" id="petPhoto" name="petPhoto" accept="image/*" 
                                           class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 
                                                  file:rounded-lg file:border-0 file:text-sm file:font-semibold
                                                  file:bg-[#2F5D50] file:text-white hover:file:bg-[#24483E]
                                                  transition duration-150">
                                    <p class="text-xs text-gray-500 mt-1">Upload a photo of the pet (JPG, PNG, GIF, etc.) - Max 5MB</p>
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
            // FILTER FUNCTIONS (CLIENT-SIDE)
            // =======================================================
            
            let currentFilter = 'all';
            let currentAgeFilter = 'all';
            let currentSearchTerm = '';
            
            function applyFilter(filterType) {
                currentFilter = filterType;
                
                // Update button styles
                document.querySelectorAll('.filter-btn').forEach(btn => {
                    btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter',
                                        'chip-male', 'chip-female', 'chip-small', 'chip-medium', 'chip-large');
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
                    
                    // Apply gender/size filter
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
                        }
                    }
                    
                    // Apply age filter
                    if (showRow && currentAgeFilter !== 'all') {
                        const ageAttr = row.getAttribute('data-age');
                        if (ageAttr) {
                            const age = parseInt(ageAttr);
                            switch (currentAgeFilter) {
                                case '0-1':
                                    if (age < 0 || age > 1) showRow = false;
                                    break;
                                case '1-3':
                                    if (age <= 1 || age > 3) showRow = false;
                                    break;
                                case '3-5':
                                    if (age <= 3 || age > 5) showRow = false;
                                    break;
                                case '5+':
                                    if (age <= 5) showRow = false;
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
                            <td colspan="11" class="px-6 py-8 text-center text-gray-500">
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
                document.getElementById('searchInput').value = '';
                
                // Reset button styles
                document.querySelectorAll('.filter-btn').forEach(btn => {
                    btn.classList.remove('bg-primary', 'text-white', 'shadow-md', 'active-filter',
                                        'chip-male', 'chip-female', 'chip-small', 'chip-medium', 'chip-large');
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
            // MODAL FUNCTIONS
            // =======================================================
            
            // Image preview function
            function previewImage(event) {
                const input = event.target;
                const previewContainer = document.getElementById('imagePreview');
                const previewImage = document.getElementById('previewImage');
                
                if (input.files && input.files[0]) {
                    const reader = new FileReader();
                    
                    reader.onload = function(e) {
                        previewImage.src = e.target.result;
                        previewContainer.classList.remove('hidden');
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
                
                openModal('createModal');
            }
            
            // Open Edit Modal with pet data
            function openEditModal(petId, name, species, breed, age, gender, size, color, healthStatus, description, photoPath) {
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
                
                // Handle existing photo
                if (photoPath && photoPath !== 'null') {
                    const previewContainer = document.getElementById('imagePreview');
                    const previewImage = document.getElementById('previewImage');
                    previewImage.src = photoPath;
                    previewContainer.classList.remove('hidden');
                } else {
                    document.getElementById('imagePreview').classList.add('hidden');
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
                    }
                }, 300);
            }
            
            // =======================================================
            // INITIALIZATION
            // =======================================================
            
            document.addEventListener('DOMContentLoaded', function() {
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
                    searchInput.addEventListener('input', function(e) {
                        currentSearchTerm = e.target.value.toLowerCase().trim();
                        filterAndDisplayPets();
                    });
                }
                
                // Auto-hide success/error messages after 5 seconds
                setTimeout(() => {
                    const messages = document.querySelectorAll('.fixed.top-4');
                    messages.forEach(msg => {
                        msg.style.display = 'none';
                    });
                }, 5000);
                
                // Apply initial filter if URL has filter parameter
                const urlFilter = urlParams.get('filter');
                const urlAgeFilter = urlParams.get('ageFilter');
                
                if (urlFilter) {
                    applyFilter(urlFilter);
                }
                if (urlAgeFilter) {
                    applyAgeFilter(urlAgeFilter);
                }
            });
        </script>
        
        <!-- Animation for messages -->
        <style>
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
    </body>
</html>