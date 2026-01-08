<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <script src="https://cdn.tailwindcss.com"></script>
        <title>Create Account</title>
        <style>
            .error-message { color: #dc2626; font-size: 0.875rem; margin-top: 0.25rem; }
            .success-message { color: #059669; font-size: 0.875rem; margin-top: 0.25rem; }
        </style>
    </head>
    <body class="bg-[#F6F3E7] min-h-screen flex items-center justify-center p-6 text-[#2B2B2B]">
        <main class="w-full max-w-4xl bg-white rounded-xl shadow-xl p-8">
            <!-- Header -->
            <div class="mb-6 pb-4 border-b border-[#E5E5E5]">
                <h1 class="text-xl font-semibold">Create Account</h1>
                <p class="text-xs text-[#2B2B2B]/70 mt-1">
                    Choose a role and fill in your details.
                </p>
            </div>

            <!-- Error/Success Messages -->
            <%
                String errorMessage = (String) request.getAttribute("errorMessage");
                String successMessage = (String) request.getAttribute("successMessage");

                if (errorMessage != null && !errorMessage.isEmpty()) {
            %>
            <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-md">
                <p class="text-red-600 text-sm"><%= errorMessage%></p>
            </div>
            <%
                }

                if (successMessage != null && !successMessage.isEmpty()) {
            %>
            <div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-md">
                <p class="text-green-600 text-sm"><%= successMessage%></p>
            </div>
            <%
                }
            %>

            <!-- FORM - Action ke RegistrationServlet -->
            <form id="registerForm" action="RegistrationServlet" method="POST" 
                  enctype="multipart/form-data" class="grid grid-cols-1 md:grid-cols-2 gap-6">

                <!-- Role Selection MASUK DALAM FORM -->
                <div class="md:col-span-2 mb-6 bg-gray-50 p-4 rounded-lg">
                    <h2 class="text-sm font-medium mb-3">Register As</h2>
                    <div class="flex gap-6">
                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="reg_role" value="adopter" id="reg_adopter" checked 
                                   onchange="toggleForms()" class="hidden"/>
                            <div class="p-4 border-2 rounded-lg hover:border-gray-300 transition-all role-card">
                                <div class="flex items-center gap-3">
                                    <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center role-circle">
                                        <div class="w-2 h-2 rounded-full bg-white role-dot"></div>
                                    </div>
                                    <div>
                                        <h3 class="font-medium">Adopter</h3>
                                        <p class="text-xs text-gray-500 mt-1">Adopt and give pets a loving home</p>
                                    </div>
                                </div>
                            </div>
                        </label>

                        <label class="flex-1 cursor-pointer">
                            <input type="radio" name="reg_role" value="shelter" id="reg_shelter" 
                                   onchange="toggleForms()" class="hidden"/>
                            <div class="p-4 border-2 rounded-lg hover:border-gray-300 transition-all role-card">
                                <div class="flex items-center gap-3">
                                    <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center role-circle">
                                        <div class="w-2 h-2 rounded-full bg-white role-dot"></div>
                                    </div>
                                    <div>
                                        <h3 class="font-medium">Shelter</h3>
                                        <p class="text-xs text-gray-500 mt-1">Register your animal shelter</p>
                                    </div>
                                </div>
                            </div>
                        </label>
                    </div>
                </div>
                <!-- LEFT COLUMN -->
                <div class="flex flex-col gap-4">
                    <!-- Profile Photo Upload -->
                    <div>
                        <label class="block text-sm font-medium mb-2">Profile Photo</label>
                        <div class="flex items-start gap-4">
                            <div class="relative w-24 h-24 border-2 border-dashed border-gray-300 rounded-full overflow-hidden bg-gray-50 flex items-center justify-center group cursor-pointer hover:border-[#2F5D50] transition-colors" onclick="document.getElementById('profile_photo').click()">
                                <img id="profilePreview" src="" alt="" class="hidden w-full h-full object-cover">
                                <div id="uploadPlaceholder" class="text-center p-3">
                                    <svg class="w-6 h-6 mx-auto text-gray-400 group-hover:text-[#2F5D50]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                                    </svg>
                                    <p class="text-xs text-gray-500 group-hover:text-[#2F5D50] mt-1">Upload</p>
                                </div>
                            </div>
                            <div class="flex-1">
                                <p class="text-sm text-gray-600 mb-2">Add a profile photo to personalize your account.</p>
                                <div class="space-y-1">
                                    <input type="file" id="profile_photo" name="profile_photo" accept="image/*" 
                                           class="hidden" onchange="previewImage(event)">
                                    <button type="button" onclick="document.getElementById('profile_photo').click()"
                                            class="px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 rounded-md transition-colors">
                                        Choose Image
                                    </button>
                                    <p class="text-xs text-gray-500">Max 2MB • JPG, PNG, GIF</p>
                                    <p id="imageError" class="text-xs text-red-500 hidden"></p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Common fields -->
                    <div>
                        <label for="full_name" class="block text-sm font-medium mb-1">Full Name *</label>
                        <input id="full_name" name="full_name" type="text" required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                               placeholder="Full Name"/>
                        <div id="nameError" class="error-message hidden"></div>
                    </div>

                    <div>
                        <label for="email" class="block text-sm font-medium mb-1">Email *</label>
                        <input id="email" name="email" type="email" required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                               placeholder="you@example.com"/>
                        <div id="emailError" class="error-message hidden"></div>
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-medium mb-1">Password *</label>
                        <input id="password" name="password" type="password" required minlength="6"
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                               placeholder="Password (min 6 characters)"/>
                        <div id="passwordError" class="error-message hidden"></div>
                    </div>

                    <div>
                        <label for="confirm_password" class="block text-sm font-medium mb-1">Confirm Password *</label>
                        <input id="confirm_password" name="confirm_password" type="password" required
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                               placeholder="Re-type your password"/>
                        <div id="confirmPasswordError" class="error-message hidden"></div>
                    </div>

                    <div>
                        <label for="phone" class="block text-sm font-medium mb-1">Phone Number</label>
                        <input id="phone" name="phone" type="tel"
                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                               placeholder="+60 12-345 6789"/>
                        <div id="phoneError" class="error-message hidden"></div>
                    </div>
                </div>

                <!-- RIGHT COLUMN -->
                <div class="flex flex-col gap-4">
                    <!-- ADOPTER FIELDS -->
                    <div id="adopter_fields">
                        <h3 class="text-sm font-medium mb-3 text-gray-700">Adopter Details</h3>
                        <div class="space-y-4">
                            <div>
                                <label for="address" class="block text-sm font-medium mb-1">Address *</label>
                                <input id="address" name="address" type="text"
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent adopter-required" 
                                       placeholder="Your full address"/>
                                <div id="addressError" class="error-message hidden"></div>
                            </div>

                            <div>
                                <label for="occupation" class="block text-sm font-medium mb-1">Occupation *</label>
                                <input id="occupation" name="occupation" type="text"
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent adopter-required" 
                                       placeholder="Your current occupation"/>
                                <div id="occupationError" class="error-message hidden"></div>
                            </div>

                            <div>
                                <label for="household" class="block text-sm font-medium mb-1">Household Type *</label>
                                <select id="household" name="household"
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent adopter-required">
                                    <option value="">Select household type</option>
                                    <option value="apartment">Apartment/Condo</option>
                                    <option value="terrace">Terrace House</option>
                                    <option value="semi_d">Semi-Detached</option>
                                    <option value="bungalow">Bungalow</option>
                                    <option value="other">Other</option>
                                </select>
                                <div id="householdError" class="error-message hidden"></div>
                            </div>

                            <div class="flex items-center gap-2">
                                <input id="has_pets" name="has_pets" type="checkbox" value="on"
                                       class="h-4 w-4 text-[#2F5D50] focus:ring-[#2F5D50] border-gray-300 rounded"/>
                                <label for="has_pets" class="text-sm cursor-pointer">
                                    I currently have other pets
                                </label>
                            </div>

                            <div>
                                <label for="adopter_notes" class="block text-sm font-medium mb-1">Additional Notes</label>
                                <textarea id="adopter_notes" name="adopter_notes" rows="6"
                                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent resize-none"
                                          placeholder="Tell us about your pet experience, living situation, or any other relevant information..."></textarea>
                            </div>
                        </div>
                    </div>

                    <!-- SHELTER FIELDS -->
                    <div id="shelter_fields" class="hidden">
                        <h3 class="text-sm font-medium mb-3 text-gray-700">Shelter Details</h3>
                        <div class="space-y-4">
                            <div>
                                <label for="shelter_name" class="block text-sm font-medium mb-1">Shelter Name *</label>
                                <input id="shelter_name" name="shelter_name" type="text"
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent shelter-required" 
                                       placeholder="Your shelter's name"/>
                                <div id="shelterNameError" class="error-message hidden"></div>
                            </div>

                            <div>
                                <label for="shelter_address" class="block text-sm font-medium mb-1">Shelter Address *</label>
                                <input id="shelter_address" name="shelter_address" type="text"
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent shelter-required" 
                                       placeholder="Full shelter address"/>
                                <div id="shelterAddressError" class="error-message hidden"></div>
                            </div>

                            <div>
                                <label for="shelter_desc" class="block text-sm font-medium mb-1">Shelter Description *</label>
                                <textarea id="shelter_desc" name="shelter_desc" rows="3"
                                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent shelter-required resize-none"
                                          placeholder="Describe your shelter, mission, facilities, etc..."></textarea>
                                <div id="shelterDescError" class="error-message hidden"></div>
                            </div>

                            <div>
                                <label for="website" class="block text-sm font-medium mb-1">Website</label>
                                <input id="website" name="website" type="url"
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent" 
                                       placeholder="https://yourshelter.com"/>
                            </div>

                            <div>
                                <label class="block text-sm font-medium mb-1">Operating Hours *</label>
                                <div class="flex gap-2">
                                    <div class="flex-1">
                                        <input id="hours_from" name="hours_from" type="time"
                                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent shelter-required"/>
                                        <p class="text-xs text-gray-500 mt-1">Opening time</p>
                                    </div>
                                    <div class="flex-1">
                                        <input id="hours_to" name="hours_to" type="time"
                                               class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent shelter-required"/>
                                        <p class="text-xs text-gray-500 mt-1">Closing time</p>
                                    </div>
                                </div>
                                <div id="hoursError" class="error-message hidden"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Buttons area -->
                <div class="md:col-span-2 mt-4 pt-4 border-t border-gray-200">
                    <div class="flex flex-col gap-3">
                        <button type="submit" id="submitBtn"
                                class="w-full bg-[#2F5D50] hover:bg-[#24483E] text-white py-3 rounded-md font-medium transition-colors shadow-sm hover:shadow-md">
                            Create Account
                        </button>
                        <p class="text-center text-sm text-gray-600">
                            Already have an account?
                            <a href="login.jsp" class="text-[#2F5D50] hover:text-[#24483E] hover:underline underline-offset-4 font-semibold ml-1">Login here</a>
                        </p>
                    </div>
                </div>
            </form>
        </main>

        <script>
            let selectedFile = null;

            function previewImage(event) {
                const file = event.target.files[0];
                const errorElement = document.getElementById('imageError');
                const preview = document.getElementById('profilePreview');
                const placeholder = document.getElementById('uploadPlaceholder');

                errorElement.classList.add('hidden');
                errorElement.textContent = '';

                if (!file) {
                    selectedFile = null;
                    preview.classList.add('hidden');
                    placeholder.classList.remove('hidden');
                    return;
                }

                const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];
                if (!validTypes.includes(file.type)) {
                    errorElement.textContent = 'Only JPG, PNG, and GIF images are allowed.';
                    errorElement.classList.remove('hidden');
                    event.target.value = '';
                    return;
                }

                const maxSize = 2 * 1024 * 1024;
                if (file.size > maxSize) {
                    errorElement.textContent = 'Image size must be less than 2MB.';
                    errorElement.classList.remove('hidden');
                    event.target.value = '';
                    return;
                }

                const reader = new FileReader();
                reader.onload = function (e) {
                    preview.src = e.target.result;
                    preview.classList.remove('hidden');
                    placeholder.classList.add('hidden');
                    selectedFile = file;
                };
                reader.readAsDataURL(file);
            }

            function updateRadioStyles() {
                const radios = document.querySelectorAll('input[name="reg_role"]');

                radios.forEach(radio => {
                    const parent = radio.closest('label');
                    const container = parent.querySelector('.role-card');
                    const circle = parent.querySelector('.role-circle');
                    const dot = parent.querySelector('.role-dot');

                    if (radio.checked) {
                        container.classList.add('border-[#2F5D50]', 'bg-[#2F5D50]/5');
                        container.classList.remove('border-gray-200');
                        circle.classList.add('border-[#2F5D50]', 'bg-[#2F5D50]');
                        circle.classList.remove('border-gray-300');
                        dot.classList.remove('hidden');
                    } else {
                        container.classList.remove('border-[#2F5D50]', 'bg-[#2F5D50]/5');
                        container.classList.add('border-gray-200');
                        circle.classList.remove('border-[#2F5D50]', 'bg-[#2F5D50]');
                        circle.classList.add('border-gray-300');
                        dot.classList.add('hidden');
                    }
                });
            }

            function toggleForms() {
                const role = document.querySelector('input[name="reg_role"]:checked').value;
                const adopterFields = document.getElementById("adopter_fields");
                const shelterFields = document.getElementById("shelter_fields");

                if (role === "adopter") {
                    adopterFields.classList.remove("hidden");
                    shelterFields.classList.add("hidden");
                } else {
                    adopterFields.classList.add("hidden");
                    shelterFields.classList.remove("hidden");
                }

                updateRadioStyles();
            }

            function validateForm() {
                let isValid = true;

                // Clear previous errors
                document.querySelectorAll('.error-message').forEach(el => {
                    el.classList.add('hidden');
                    el.textContent = '';
                });

                // Get values
                const fullName = document.getElementById('full_name').value.trim();
                const email = document.getElementById('email').value.trim();
                const password = document.getElementById('password').value;
                const confirmPassword = document.getElementById('confirm_password').value;
                const role = document.querySelector('input[name="reg_role"]:checked').value;

                // Validate name
                if (!fullName) {
                    document.getElementById('nameError').textContent = 'Full name is required';
                    document.getElementById('nameError').classList.remove('hidden');
                    isValid = false;
                }

                // Validate email
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!email) {
                    document.getElementById('emailError').textContent = 'Email is required';
                    document.getElementById('emailError').classList.remove('hidden');
                    isValid = false;
                } else if (!emailRegex.test(email)) {
                    document.getElementById('emailError').textContent = 'Please enter a valid email address';
                    document.getElementById('emailError').classList.remove('hidden');
                    isValid = false;
                }

                // Validate password
                if (password.length < 6) {
                    document.getElementById('passwordError').textContent = 'Password must be at least 6 characters';
                    document.getElementById('passwordError').classList.remove('hidden');
                    isValid = false;
                }

                // Validate confirm password
                if (password !== confirmPassword) {
                    document.getElementById('confirmPasswordError').textContent = 'Passwords do not match';
                    document.getElementById('confirmPasswordError').classList.remove('hidden');
                    isValid = false;
                }

                // Role-specific validation
                if (role === "adopter") {
                    const address = document.getElementById('address').value.trim();
                    const occupation = document.getElementById('occupation').value.trim();
                    const household = document.getElementById('household').value;

                    if (!address) {
                        document.getElementById('addressError').textContent = 'Address is required';
                        document.getElementById('addressError').classList.remove('hidden');
                        isValid = false;
                    }

                    if (!occupation) {
                        document.getElementById('occupationError').textContent = 'Occupation is required';
                        document.getElementById('occupationError').classList.remove('hidden');
                        isValid = false;
                    }

                    if (!household) {
                        document.getElementById('householdError').textContent = 'Household type is required';
                        document.getElementById('householdError').classList.remove('hidden');
                        isValid = false;
                    }
                } else if (role === "shelter") {
                    const shelterName = document.getElementById('shelter_name').value.trim();
                    const shelterAddress = document.getElementById('shelter_address').value.trim();
                    const shelterDesc = document.getElementById('shelter_desc').value.trim();
                    const hoursFrom = document.getElementById('hours_from').value;
                    const hoursTo = document.getElementById('hours_to').value;

                    if (!shelterName) {
                        document.getElementById('shelterNameError').textContent = 'Shelter name is required';
                        document.getElementById('shelterNameError').classList.remove('hidden');
                        isValid = false;
                    }

                    if (!shelterAddress) {
                        document.getElementById('shelterAddressError').textContent = 'Shelter address is required';
                        document.getElementById('shelterAddressError').classList.remove('hidden');
                        isValid = false;
                    }

                    if (!shelterDesc) {
                        document.getElementById('shelterDescError').textContent = 'Shelter description is required';
                        document.getElementById('shelterDescError').classList.remove('hidden');
                        isValid = false;
                    }

                    if (!hoursFrom || !hoursTo) {
                        document.getElementById('hoursError').textContent = 'Operating hours are required';
                        document.getElementById('hoursError').classList.remove('hidden');
                        isValid = false;
                    }
                }

                // Validate file if selected
                if (selectedFile) {
                    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/jpg'];
                    if (!validTypes.includes(selectedFile.type)) {
                        document.getElementById('imageError').textContent = 'Only JPG, PNG, and GIF images are allowed';
                        document.getElementById('imageError').classList.remove('hidden');
                        isValid = false;
                    }

                    const maxSize = 2 * 1024 * 1024;
                    if (selectedFile.size > maxSize) {
                        document.getElementById('imageError').textContent = 'Image size must be less than 2MB';
                        document.getElementById('imageError').classList.remove('hidden');
                        isValid = false;
                    }
                }

                return isValid;
            }

            // Attach validation to form submit
            document.getElementById('registerForm').addEventListener('submit', function (e) {
                if (!validateForm()) {
                    e.preventDefault(); // Stop form submission
                    return false;
                }

                // Show loading state
                const submitBtn = document.getElementById('submitBtn');
                submitBtn.innerHTML = 'Creating Account...';
                submitBtn.disabled = true;
                submitBtn.classList.add('opacity-75', 'cursor-not-allowed');

                // Allow form to submit naturally
                return true;
            });

            // Real-time validation
            document.querySelectorAll('input, select, textarea').forEach(input => {
                input.addEventListener('blur', function () {
                    if (this.value.trim() !== '') {
                        const errorId = this.id + 'Error';
                        const errorElement = document.getElementById(errorId);
                        if (errorElement) {
                            errorElement.classList.add('hidden');
                        }
                    }
                });
            });

            // Initialize page
            document.addEventListener("DOMContentLoaded", () => {
                updateRadioStyles();
                toggleForms();

                // Set default hours
                document.getElementById('hours_from').value = '09:00';
                document.getElementById('hours_to').value = '17:00';

                // Check for URL parameters for error/success
                const urlParams = new URLSearchParams(window.location.search);
                const error = urlParams.get('error');
                const success = urlParams.get('success');
                const role = urlParams.get('role'); // TAMBAH ini

                if (error) {
                    alert("Error: " + decodeURIComponent(error));
                }
                if (success && role) {
                    // JANGAN guna alert, guna custom modal
                    showCustomSuccessModal(role, decodeURIComponent(success));

                    // Clear URL parameters supaya tak muncul lagi pada refresh
                    window.history.replaceState({}, document.title, window.location.pathname);
                }
            });

// Function untuk show custom modal
            function showCustomSuccessModal(role, message) {
                // Determine icon based on role
                let iconHTML, title;

                if (role === 'adopter') {
                    iconHTML = '<svg class="h-8 w-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>';
                    title = '🎉 Registration Successful!';
                } else {
                    iconHTML = '<svg class="h-8 w-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>';
                    title = '🏠 Registration Submitted';
                }

                // Color class based on role
                const bgColorClass = role === 'adopter' ? 'bg-green-100' : 'bg-blue-100';

                // Create modal HTML dengan PROPER string concatenation
                const modalHTML =
                        '<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">' +
                        '<div class="bg-white rounded-xl p-8 max-w-md w-full mx-4 shadow-2xl">' +
                        '<div class="text-center">' +
                        '<div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full ' + bgColorClass + ' mb-4">' +
                        iconHTML +
                        '</div>' +
                        '<h3 class="text-xl font-semibold text-gray-900 mb-3">' +
                        title +
                        '</h3>' +
                        '<p class="text-gray-600 mb-6 text-sm leading-relaxed">' +
                        message +
                        '</p>' +
                        '<div class="space-y-3">' +
                        '<button id="continueToLoginBtn" class="w-full bg-[#2F5D50] text-white py-3 rounded-md font-medium hover:bg-[#24483E] transition-colors shadow-sm">' +
                        'Continue to Login' +
                        '</button>' +
                        '<button id="stayOnPageBtn" class="w-full bg-gray-100 text-gray-700 py-3 rounded-md font-medium hover:bg-gray-200 transition-colors">' +
                        'Stay on This Page' +
                        '</button>' +
                        '</div>' +
                        '</div>' +
                        '</div>' +
                        '</div>';

                // Add to body
                document.body.insertAdjacentHTML('beforeend', modalHTML);
                document.body.classList.add('overflow-hidden');

                // Add event listeners untuk buttons
                document.getElementById('continueToLoginBtn').addEventListener('click', function () {
                    window.location.href = 'login.jsp';
                });

                document.getElementById('stayOnPageBtn').addEventListener('click', function () {
                    const modal = document.querySelector('.fixed.inset-0.bg-black');
                    if (modal) {
                        modal.remove();
                    }
                    document.body.classList.remove('overflow-hidden');
                });

                // Auto redirect selepas 10 saat
                setTimeout(() => {
                    window.location.href = 'login.jsp';
                }, 10000);
            }

        </script>
    </body>
</html>