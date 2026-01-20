<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.PetsDAO" %>
<%@ page import="com.rimba.adopt.dao.ShelterDAO" %>
<%@ page import="com.rimba.adopt.dao.AdoptionRequestDAO" %>
<%@ page import="com.rimba.adopt.model.Pets" %>
<%@ page import="com.rimba.adopt.model.Shelter" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>

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

    // Get pet ID from parameter
    String petIdParam = request.getParameter("id");
    System.out.println("DEBUG: petIdParam = " + petIdParam);

    Pets pet = null;
    Shelter shelter = null;
    boolean hasApplied = false;
    String applicationStatus = "";
    double avgRating = 0.0;
    int reviewCount = 0;

    if (petIdParam != null && !petIdParam.isEmpty()) {
        try {
            int petId = Integer.parseInt(petIdParam);
            System.out.println("DEBUG: Parsed petId = " + petId);

            // Get pet with shelter info
            PetsDAO petsDAO = new PetsDAO();
            Map<String, Object> petData = petsDAO.getPetWithShelterInfo(petId);

            if (petData == null) {
                System.out.println("DEBUG: Pet not found, redirecting to pet_list.jsp");
                response.sendRedirect("pet_list.jsp");
                return;
            }

            // Get pet object
            pet = (Pets) petData.get("pet");

            // Get shelter info using ShelterDAO
            ShelterDAO shelterDAO = new ShelterDAO();
            int petShelterId = pet.getShelterId();
            System.out.println("DEBUG pet_info.jsp: pet.getShelterId() = " + petShelterId);

            shelter = shelterDAO.getShelterWithRating(petShelterId);
            System.out.println("DEBUG pet_info.jsp: shelter from DAO = " + (shelter != null ? shelter.getShelterName() : "NULL"));

            if (shelter == null) {
                System.out.println("DEBUG pet_info.jsp: Shelter NULL, using fallback");
                // Fallback to basic shelter info from petData
                shelter = new Shelter();
                shelter.setShelterId(petShelterId);
                shelter.setShelterName((String) petData.get("shelter_name"));
                shelter.setShelterAddress((String) petData.get("shelter_address"));
                shelter.setPhotoPath((String) petData.get("shelter_photo_path"));

                // CRITICAL: Set default values untuk fields lain
                shelter.setEmail((String) petData.get("shelter_email"));
                shelter.setPhone((String) petData.get("shelter_phone"));
                shelter.setOperatingHours("Mon-Fri: 9AM-6PM"); // default
                shelter.setShelterDescription("Animal shelter providing care and adoption services.");
            }

            System.out.println("DEBUG pet_info.jsp: Final shelter.getShelterId() = " + shelter.getShelterId());

            // Get adoption request status if user is logged in
            int userId = SessionUtil.getUserId(session);
            if (userId > 0) {
                AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
                List<Map<String, Object>> applications = requestDAO.getApplicationsByAdopter(userId);

                for (Map<String, Object> app : applications) {
                    if (petId == (Integer) app.get("pet_id")) {
                        hasApplied = true;
                        applicationStatus = (String) app.get("status");
                        break;
                    }
                }
            }

            // Get shelter rating
            if (shelter != null) {
                avgRating = shelter.getAvgRating();
                reviewCount = shelter.getReviewCount();
            }

            System.out.println("DEBUG: Pet found - ID: " + pet.getPetId() + ", Name: " + pet.getName());
            System.out.println("DEBUG: Shelter found - ID: " + shelter.getShelterId() + ", Name: " + shelter.getShelterName());

        } catch (NumberFormatException e) {
            System.err.println("ERROR: Invalid pet ID format: " + petIdParam);
            response.sendRedirect("pet_list.jsp");
            return;
        } catch (SQLException e) {
            System.err.println("ERROR getting pet data: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("pet_list.jsp");
            return;
        }
    } else {
        System.out.println("DEBUG: No pet ID parameter, redirecting to pet_list.jsp");
        response.sendRedirect("pet_list.jsp");
        return;
    }
%>

<%!
    // Helper functions (declaration section)
    String capitalizeFirstLetter(String input) {
        if (input == null || input.isEmpty()) {
            return "";
        }
        return input.substring(0, 1).toUpperCase() + input.substring(1).toLowerCase();
    }

    String escapeHtml(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    String getSpeciesIcon(String species) {
        if (species == null) {
            return "fa-paw";
        }

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

    String generateStars(double rating) {
        StringBuilder stars = new StringBuilder();
        int fullStars = (int) Math.floor(rating);
        boolean hasHalfStar = (rating - fullStars) >= 0.5;

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
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><%= escapeHtml(pet.getName())%> - Pet Details - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
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
                max-width: 600px;
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

            /* Gender badges */
            .gender-male {
                background-color: #2F5D50;
                color: white;
            }

            .gender-female {
                background-color: #C49A6C;
                color: white;
            }

            .info-card {
                border-left: 4px solid #2F5D50;
            }

            /* Make shelter info static */
            .shelter-info-container {
                position: relative;
                margin-top: 0;
            }

            .star-rating {
                color: #C49A6C;
            }
        </style>
        <script>
            console.log('DEBUG: Pet ID = <%= pet.getPetId()%>');
            console.log('DEBUG: Shelter ID = <%= shelter != null ? shelter.getShelterId() : "NULL"%>');
            console.log('DEBUG: Shelter Name = <%= shelter != null ? shelter.getShelterName() : "NULL"%>');
        </script>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Main Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Back Button and Title -->
                <div class="mb-8">
                    <div class="flex items-center justify-between mb-2">
                        <a href="pet_list.jsp" class="flex items-center text-[#2F5D50] hover:text-[#24483E]">
                            <i class="fas fa-arrow-left mr-2"></i> Back to Pets
                        </a>
                        <div class="bg-[#6DBF89] text-[#06321F] px-4 py-2 rounded-full text-sm font-medium">
                            <i class="fas fa-heart mr-2"></i> 
                            <% if ("available".equals(pet.getAdoptionStatus())) { %>
                            Available for Adoption
                            <% } else { %>
                            Adopted
                            <% }%>
                        </div>
                    </div>
                    <h1 class="text-3xl font-bold text-[#2F5D50]">Pet Details</h1>
                </div>

                <!-- Full Width Pet Image -->
                <div class="mb-8">
                    <img src="<%= pet.getPhotoPath() != null ? pet.getPhotoPath() : "animal_picture/default.png"%>" 
                         alt="<%= escapeHtml(pet.getName())%>" 
                         class="w-full h-96 object-cover rounded-xl">
                </div>

                <!-- Two Column Layout - FIXED -->
                <div class="flex flex-col lg:flex-row gap-8">
                    <!-- Left Column: Pet Information -->
                    <div class="lg:w-2/3">
                        <div class="bg-white p-6 rounded-xl border border-[#E5E5E5]">
                            <div class="flex justify-between items-start mb-6">
                                <div>
                                    <h2 class="text-2xl font-bold text-[#2B2B2B] mb-2"><%= escapeHtml(pet.getName())%></h2>
                                    <div class="flex items-center flex-wrap gap-3">
                                        <span class="<%= "male".equals(pet.getGender()) ? "gender-male" : "gender-female"%> px-3 py-1 rounded-full text-sm font-medium">
                                            <i class="fas <%= "male".equals(pet.getGender()) ? "fa-mars" : "fa-venus"%> mr-1"></i> 
                                            <%= capitalizeFirstLetter(pet.getGender())%>
                                        </span>
                                        <span class="bg-[#A8E6CF] text-[#2B2B2B] px-3 py-1 rounded-full text-sm">
                                            <i class="fas <%= getSpeciesIcon(pet.getSpecies())%> mr-1"></i>
                                            <%= capitalizeFirstLetter(pet.getSpecies())%>
                                        </span>
                                        <span class="bg-[#A8E6CF] text-[#2B2B2B] px-3 py-1 rounded-full text-sm">
                                            <%= pet.getAge() != null ? pet.getAge() + " years old" : "Age unknown"%>
                                        </span>
                                        <span class="bg-[#A8E6CF] text-[#2B2B2B] px-3 py-1 rounded-full text-sm">
                                            <%= capitalizeFirstLetter(pet.getSize())%> Size
                                        </span>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <p class="text-[#888] text-sm">Pet ID</p>
                                    <p class="font-bold text-[#2F5D50]">#PET<%= String.format("%03d", pet.getPetId())%></p>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                                <div class="info-card bg-[#F9F9F9] p-5 rounded-xl">
                                    <h3 class="font-semibold text-[#2B2B2B] mb-3 text-lg">Basic Information</h3>
                                    <div class="space-y-3">
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Breed</span>
                                            <span class="font-medium"><%= pet.getBreed() != null ? escapeHtml(pet.getBreed()) : "Mixed Breed"%></span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Color</span>
                                            <span class="font-medium"><%= pet.getColor() != null ? escapeHtml(pet.getColor()) : "Not specified"%></span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Age</span>
                                            <span class="font-medium"><%= pet.getAge() != null ? pet.getAge() + " years" : "Unknown"%></span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Size</span>
                                            <span class="font-medium"><%= capitalizeFirstLetter(pet.getSize())%></span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Gender</span>
                                            <span class="font-medium"><%= capitalizeFirstLetter(pet.getGender())%></span>
                                        </div>
                                    </div>
                                </div>

                                <div class="info-card bg-[#F9F9F9] p-5 rounded-xl">
                                    <h3 class="font-semibold text-[#2B2B2B] mb-3 text-lg">Health & Care</h3>
                                    <div class="space-y-3">
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Health Status</span>
                                            <%
                                                String healthStatus = pet.getHealthStatus();
                                                String healthStatusClass = "text-[#2B2B2B]";
                                                if (healthStatus != null) {
                                                    if (healthStatus.toLowerCase().contains("excellent")
                                                            || healthStatus.toLowerCase().contains("good")
                                                            || healthStatus.toLowerCase().contains("healthy")) {
                                                        healthStatusClass = "text-[#6DBF89]";
                                                    }
                                                }
                                            %>
                                            <span class="font-medium <%= healthStatusClass%>">
                                                <%= healthStatus != null ? capitalizeFirstLetter(healthStatus) : "Good"%>
                                            </span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Vaccinated</span>
                                            <span class="font-medium text-[#6DBF89]">Yes</span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Dewormed</span>
                                            <span class="font-medium text-[#6DBF89]">Yes</span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Spayed/Neutered</span>
                                            <span class="font-medium"><%= "male".equals(pet.getGender()) ? "Neutered" : "Spayed"%></span>
                                        </div>
                                        <div class="flex justify-between">
                                            <span class="text-[#666]">Microchipped</span>
                                            <span class="font-medium text-[#6DBF89]">Yes</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="mb-8">
                                <h3 class="font-semibold text-[#2B2B2B] mb-3 text-lg">About <%= escapeHtml(pet.getName())%></h3>
                                <div class="text-[#666] leading-relaxed space-y-4">
                                    <p>
                                        <%= pet.getDescription() != null && !pet.getDescription().isEmpty()
                                                ? escapeHtml(pet.getDescription())
                                                : escapeHtml(pet.getName()) + " is a friendly and lovable pet looking for a forever home."%>
                                    </p>
                                    <p>
                                        This pet has been well cared for and is ready to become part of a loving family.
                                    </p>
                                </div>
                            </div>

                            <div class="mb-8">
                                <h3 class="font-semibold text-[#2B2B2B] mb-3 text-lg">Special Requirements</h3>
                                <div class="bg-[#F0F7F4] p-4 rounded-lg">
                                    <ul class="list-disc pl-5 text-[#666] space-y-2">
                                        <li>Requires daily exercise and attention</li>
                                        <li>Prefers a loving home environment</li>
                                        <li>Good with patient owners</li>
                                        <li>Regular veterinary checkups needed</li>
                                        <li>Proper nutrition and care required</li>
                                    </ul>
                                </div>
                            </div>

                            <!-- Apply for Adoption Button -->
                            <div class="text-center">
                                <% if ("available".equals(pet.getAdoptionStatus())) { %>
                                <% if (hasApplied) {%>
                                <div class="mb-4 p-4 bg-[#F0F7F4] rounded-lg">
                                    <p class="text-[#2B2B2B] font-medium">
                                        <i class="fas fa-info-circle text-[#2F5D50] mr-2"></i>
                                        You have already applied to adopt this pet. Status: <span class="font-bold"><%= capitalizeFirstLetter(applicationStatus)%></span>
                                    </p>
                                </div>
                                <button class="px-8 py-4 bg-gray-400 text-white font-bold text-lg rounded-lg cursor-not-allowed" disabled>
                                    <i class="fas fa-check mr-2"></i> Already Applied
                                </button>
                                <% } else {%>
                                <button id="applyAdoptionBtn" class="px-8 py-4 bg-[#2F5D50] text-white font-bold text-lg rounded-lg hover:bg-[#24483E] transition duration-300">
                                    <i class="fas fa-heart mr-2"></i> Apply to Adopt <%= escapeHtml(pet.getName())%>
                                </button>
                                <% } %>
                                <% } else { %>
                                <button class="px-8 py-4 bg-gray-400 text-white font-bold text-lg rounded-lg cursor-not-allowed" disabled>
                                    <i class="fas fa-check mr-2"></i> Already Adopted
                                </button>
                                <% }%>
                                <p class="text-[#888] text-sm mt-3">By applying, you agree to our adoption terms and conditions</p>
                            </div>
                        </div>
                    </div>

                    <!-- Right Column: Shelter Information - FIXED POSITION -->
                    <div class="lg:w-1/3 shelter-info-container">
                        <!-- Shelter Information Card -->
                        <div class="bg-white p-6 rounded-xl border border-[#E5E5E5] mb-6">
                            <h3 class="text-xl font-bold text-[#2B2B2B] mb-4">Shelter Information</h3>

                            <div class="flex items-center mb-6">
                                <div class="w-16 h-16 rounded-full overflow-hidden mr-4">
                                    <img src="<%= shelter.getPhotoPath() != null ? shelter.getPhotoPath() : "profile_picture/shelter/default.png"%>" 
                                         alt="<%= escapeHtml(shelter.getShelterName())%>" 
                                         class="w-full h-full object-cover">
                                </div>
                                <div>
                                    <h4 class="font-bold text-[#2B2B2B] text-lg"><%= escapeHtml(shelter.getShelterName())%></h4>
                                    <div class="flex items-center mt-1">
                                        <div class="star-rating text-[#C49A6C] mr-2">
                                            <%= generateStars(avgRating)%>
                                        </div>
                                        <span class="text-sm text-[#888]">
                                            <%= String.format("%.1f", avgRating)%> (<%= reviewCount%> reviews)
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div class="space-y-4 mb-6">
                                <div class="flex items-start">
                                    <div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">
                                        <i class="fas fa-map-marker-alt text-[#2F5D50]"></i>
                                    </div>
                                    <div>
                                        <p class="text-[#666] text-sm">Location</p>
                                        <p class="font-medium"><%= shelter.getShelterAddress() != null ? escapeHtml(shelter.getShelterAddress()) : "Address not available"%></p>
                                    </div>
                                </div>

                                <div class="flex items-start">
                                    <div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">
                                        <i class="fas fa-phone-alt text-[#2F5D50]"></i>
                                    </div>
                                    <div>
                                        <p class="text-[#666] text-sm">Contact</p>
                                        <p class="font-medium"><%= shelter.getPhone() != null ? shelter.getPhone() : "N/A"%></p>
                                    </div>
                                </div>

                                <div class="flex items-start">
                                    <div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">
                                        <i class="fas fa-envelope text-[#2F5D50]"></i>
                                    </div>
                                    <div>
                                        <p class="text-[#666] text-sm">Email</p>
                                        <p class="font-medium"><%= shelter.getEmail() != null ? shelter.getEmail() : "N/A"%></p>
                                    </div>
                                </div>

                                <div class="flex items-start">
                                    <div class="bg-[#F0F7F4] p-2 rounded-lg mr-3">
                                        <i class="fas fa-clock text-[#2F5D50]"></i>
                                    </div>
                                    <div>
                                        <p class="text-[#666] text-sm">Operating Hours</p>
                                        <p class="font-medium"><%= shelter.getOperatingHours() != null ? escapeHtml(shelter.getOperatingHours()) : "Mon-Fri: 9AM-6PM"%></p>
                                    </div>
                                </div>
                            </div>

                            <div class="mb-6">
                                <h4 class="font-semibold text-[#2B2B2B] mb-2">About This Shelter</h4>
                                <p class="text-[#666] text-sm">
                                    <%
                                        String shelterDesc = shelter.getShelterDescription();
                                        if (shelterDesc != null && !shelterDesc.isEmpty()) {
                                            if (shelterDesc.length() > 150) {
                                                out.print(escapeHtml(shelterDesc.substring(0, 150) + "..."));
                                            } else {
                                                out.print(escapeHtml(shelterDesc));
                                            }
                                        } else {
                                            out.print("Animal shelter providing care and adoption services.");
                                        }
                                    %>
                                </p>
                            </div>

                            <a href="shelter_info.jsp?id=<%= shelter.getShelterId()%>" class="block w-full text-center py-3 bg-[#6DBF89] text-[#06321F] font-medium rounded-lg hover:bg-[#57A677] transition duration-300">
                                <i class="fas fa-info-circle mr-2"></i> Learn More About Shelter
                            </a>
                        </div>

                        <!-- Adoption Stats -->
                        <div class="bg-white p-6 rounded-xl border border-[#E5E5E5]">
                            <h3 class="text-xl font-bold text-[#2B2B2B] mb-4">Pet Information</h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div class="flex flex-col items-center justify-center p-6 bg-[#F9F9F9] rounded-lg">
                                    <p class="text-2xl font-bold text-[#2F5D50]">ID</p>
                                    <p class="text-sm text-[#666] mt-1"><%= pet.getPetId()%></p>
                                </div>
                                <div class="flex flex-col items-center justify-center p-6 bg-[#F9F9F9] rounded-lg">
                                    <p class="text-2xl font-bold text-[#2F5D50]">
                                        <% if ("available".equals(pet.getAdoptionStatus())) { %>
                                        Available
                                        <% } else { %>
                                        Adopted
                                        <% }%>
                                    </p>
                                    <p class="text-sm text-[#666] mt-1">Status</p>
                                </div>
                            </div>
                            <div class="mt-4 pt-4 border-t border-[#E5E5E5]">
                                <div class="flex items-center justify-between mb-2">
                                    <span class="text-[#666]">Species</span>
                                    <span class="font-medium"><%= capitalizeFirstLetter(pet.getSpecies())%></span>
                                </div>
                                <div class="flex items-center justify-between">
                                    <span class="text-[#666]">Shelter</span>
                                    <span class="font-medium"><%= escapeHtml(shelter.getShelterName())%></span>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>

            </div>
        </main>

        <!-- Adoption Application Modal -->
        <div id="adoptionModal" class="modal-overlay">
            <div class="modal-content p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold text-[#2B2B2B]">Apply to Adopt <%= escapeHtml(pet.getName())%></h3>
                    <button id="closeModal" class="text-[#888] hover:text-[#2B2B2B]">
                        <i class="fas fa-times text-2xl"></i>
                    </button>
                </div>

                <form id="adoptionForm">
                    <input type="hidden" id="petId" name="petId" value="<%= pet.getPetId()%>">
                    <input type="hidden" id="shelterId" name="shelterId" value="<%= shelter.getShelterId()%>">

                    <div class="mb-6">
                        <p class="text-[#666] mb-4">
                            You're applying to adopt <span class="font-bold text-[#2F5D50]"><%= escapeHtml(pet.getName())%></span> 
                            from <span class="font-bold text-[#2F5D50]"><%= escapeHtml(shelter.getShelterName())%></span>.
                        </p>
                        <div class="bg-[#F0F7F4] p-4 rounded-lg mb-4">
                            <p class="text-sm text-[#666]">
                                <i class="fas fa-info-circle mr-2 text-[#2F5D50]"></i> 
                                Your application will be reviewed by the shelter. They may contact you for additional information or to schedule a meet-and-greet.
                            </p>
                        </div>
                    </div>

                    <div class="mb-6">
                        <label for="adopterMessage" class="block text-[#2B2B2B] mb-2 font-medium">Why do you want to adopt this pet? *</label>
                        <textarea id="adopterMessage" name="adopterMessage" rows="5" class="w-full p-3 border border-[#E5E5E5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#6DBF89]" placeholder="Tell us about yourself, your experience with pets, and why you think you'd be a good fit for this animal..." required></textarea>
                        <p class="text-[#888] text-sm mt-1">Please provide detailed information to help the shelter assess your application.</p>
                    </div>

                    <div class="mb-6">
                        <label class="block text-[#2B2B2B] mb-2 font-medium">Adoption Terms</label>
                        <div class="bg-[#F9F9F9] p-4 rounded-lg max-h-40 overflow-y-auto">
                            <div class="space-y-3">
                                <div class="flex items-start">
                                    <input type="checkbox" id="term1" name="terms" class="mt-1 mr-3" required>
                                    <label for="term1" class="text-[#666] text-sm">I understand that adoption is a lifelong commitment and I am prepared to care for this pet for its entire life.</label>
                                </div>
                                <div class="flex items-start">
                                    <input type="checkbox" id="term2" name="terms" class="mt-1 mr-3" required>
                                    <label for="term2" class="text-[#666] text-sm">I confirm that I am at least 21 years old and have valid identification.</label>
                                </div>
                                <div class="flex items-start">
                                    <input type="checkbox" id="term3" name="terms" class="mt-1 mr-3" required>
                                    <label for="term3" class="text-[#666] text-sm">I agree to provide proper veterinary care, nutrition, and living conditions for this pet.</label>
                                </div>
                                <div class="flex items-start">
                                    <input type="checkbox" id="term4" name="terms" class="mt-1 mr-3" required>
                                    <label for="term4" class="text-[#666] text-sm">I understand that the shelter reserves the right to deny my application at their discretion.</label>
                                </div>
                                <div class="flex items-start">
                                    <input type="checkbox" id="term5" name="terms" class="mt-1 mr-3" required>
                                    <label for="term5" class="text-[#666] text-sm">I agree to allow a home visit if requested by the shelter as part of the adoption process.</label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="flex justify-end space-x-3">
                        <button type="button" id="cancelAdoption" class="px-6 py-3 border border-[#E5E5E5] text-[#2B2B2B] font-medium rounded-lg hover:bg-[#F6F3E7]">
                            Cancel
                        </button>
                        <button type="submit" class="px-6 py-3 bg-[#2F5D50] text-white font-medium rounded-lg hover:bg-[#24483E] transition duration-300">
                            <i class="fas fa-paper-plane mr-2"></i> Submit Application
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />
        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
            // DOM Elements
            var adoptionModal = document.getElementById('adoptionModal');
            var applyAdoptionBtn = document.getElementById('applyAdoptionBtn');
            var closeModalBtn = document.getElementById('closeModal');
            var cancelAdoptionBtn = document.getElementById('cancelAdoption');
            var adoptionForm = document.getElementById('adoptionForm');

            // Initialize
            document.addEventListener('DOMContentLoaded', function () {
                attachEventListeners();
            });

            // Open adoption modal
            function openAdoptionModal() {
                if (adoptionModal) {
                    adoptionModal.classList.add('show');
                    setTimeout(function () {
                        var modalContent = adoptionModal.querySelector('.modal-content');
                        if (modalContent) {
                            modalContent.classList.add('show');
                        }
                    }, 10);
                }
            }

            // Close adoption modal
            function closeAdoptionModal() {
                if (adoptionModal) {
                    var modalContent = adoptionModal.querySelector('.modal-content');
                    if (modalContent) {
                        modalContent.classList.remove('show');
                    }

                    setTimeout(function () {
                        adoptionModal.classList.remove('show');
                        resetAdoptionForm();
                    }, 300);
                }
            }

            // Reset adoption form
            function resetAdoptionForm() {
                if (adoptionForm) {
                    adoptionForm.reset();
                }
            }

            // Handle adoption form submission - FIXED VERSION
            function handleAdoptionSubmit(e) {
                e.preventDefault();

                // Validate required fields
                var adopterMessage = document.getElementById('adopterMessage');
                if (!adopterMessage || !adopterMessage.value.trim()) {
                    alert('Please tell us why you want to adopt this pet.');
                    return;
                }

                // Check if all terms are accepted
                var terms = document.querySelectorAll('input[name="terms"]');
                var allTermsAccepted = true;

                for (var i = 0; i < terms.length; i++) {
                    if (!terms[i].checked) {
                        allTermsAccepted = false;
                        break;
                    }
                }

                if (!allTermsAccepted) {
                    alert('Please accept all adoption terms to proceed.');
                    return;
                }

                // Submit via AJAX to servlet
                var petId = document.getElementById('petId').value;
                var shelterId = document.getElementById('shelterId').value;
                var message = adopterMessage.value.trim();

                // VALIDATE shelterId
                if (!shelterId || shelterId === '0' || shelterId === 'null') {
                    alert('Error: Shelter ID is missing. Please refresh the page and try again.');
                    return;
                }

                // **FIX: Use URL encoded parameters instead of FormData**
                var params = new URLSearchParams();
                params.append('action', 'applyAdoption');
                params.append('petId', petId);
                params.append('shelterId', shelterId);
                params.append('adopterMessage', message);

                // Show loading
                var submitBtn = adoptionForm.querySelector('button[type="submit"]');
                var originalText = submitBtn.innerHTML;
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Submitting...';
                submitBtn.disabled = true;

                // **FIX: Send as application/x-www-form-urlencoded**
                fetch('ManageAdoptionRequest', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: params.toString()
                })
                        .then(function (response) {
                            return response.json();
                        })
                        .then(function (data) {
                            if (data.success) {
                                alert('Your adoption application has been submitted successfully! The shelter will contact you within 3-5 business days.');
                                // Close modal and reload page
                                closeAdoptionModal();
                                // Reload page to update status
                                setTimeout(function () {
                                    location.reload();
                                }, 1000);
                            } else {
                                alert('Application failed: ' + data.message);
                                submitBtn.innerHTML = originalText;
                                submitBtn.disabled = false;
                            }
                        })
                        .catch(function (error) {
                            console.error('Error:', error);
                            alert('Failed to submit application. Please try again.');
                            submitBtn.innerHTML = originalText;
                            submitBtn.disabled = false;
                        });
            }

            // Attach event listeners - ES5 COMPATIBLE
            function attachEventListeners() {
                if (applyAdoptionBtn) {
                    applyAdoptionBtn.addEventListener('click', openAdoptionModal);
                }
                if (closeModalBtn) {
                    closeModalBtn.addEventListener('click', closeAdoptionModal);
                }
                if (cancelAdoptionBtn) {
                    cancelAdoptionBtn.addEventListener('click', closeAdoptionModal);
                }

                // Close modal when clicking outside
                if (adoptionModal) {
                    adoptionModal.addEventListener('click', function (e) {
                        if (e.target === adoptionModal) {
                            closeAdoptionModal();
                        }
                    });
                }

                // Adoption form submission
                if (adoptionForm) {
                    adoptionForm.addEventListener('submit', handleAdoptionSubmit);
                }
            }
        </script>

    </body>
</html>