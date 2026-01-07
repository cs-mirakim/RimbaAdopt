<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <script src="https://cdn.tailwindcss.com"></script>
        <title>Login</title>
    </head>

    <body class="bg-[#F6F3E7] min-h-screen flex items-center justify-center p-6">

        <div class="w-full max-w-4xl bg-white rounded-xl shadow-xl flex overflow-hidden">

            <!-- LEFT SIDE -->
            <div class="hidden md:flex flex-col items-center justify-center 
                 bg-[#2F5D50] text-white w-1/2 p-8">

                <div class="w-56 h-56 rounded-full bg-white flex items-center justify-center mb-6 shadow-lg">
                    <img src="includes/logo.png" alt="Rimba Logo" class="w-40 h-40 object-contain" />
                </div>

                <h1 class="text-2xl font-bold text-center">Rimba Pet Adoption System</h1>
                <p class="mt-2 text-center text-sm opacity-90">
                    Helping pets find loving homes
                </p>
            </div>

            <!-- RIGHT SIDE (FORM) -->
            <div class="w-full md:w-1/2 p-8 text-[#2B2B2B]">

                <h1 class="text-2xl font-bold mb-6 text-left pb-2 border-b border-[#E5E5E5]">
                    Login
                </h1>

                <p class="text-sm text-gray-500 mb-4">
                    *For storyboard/testing purposes, you may enter any random email and password.*
                </p>


                <!-- roles -->
                <fieldset class="mb-4">
                    <legend class="block mb-2 font-medium">Login As</legend>
                    <div class="flex gap-4">
                        <label class="inline-flex items-center gap-2">
                            <input type="radio" name="role" value="admin" checked />
                            <span>Admin</span>
                        </label>
                        <label class="inline-flex items-center gap-2">
                            <input type="radio" name="role" value="shelter" />
                            <span>Shelter</span>
                        </label>
                        <label class="inline-flex items-center gap-2">
                            <input type="radio" name="role" value="adopter" />
                            <span>Adopter</span>
                        </label>
                    </div>
                </fieldset>

                <!-- GANTI FORM YANG LAMA -->
                <form id="loginForm" action="login" method="POST" class="space-y-4">

                    <!-- Hidden input untuk role -->
                    <input type="hidden" name="role" id="roleInput" value="admin" />

                    <div>
                        <label for="login_email" class="block text-sm font-medium mb-1">
                            Email
                        </label>
                        <input
                            id="login_email"
                            name="login_email"
                            type="email"
                            required
                            class="w-full p-2 border border-[#E5E5E5] rounded-md"
                            placeholder="you@example.com"
                            />
                    </div>

                    <div>
                        <label for="login_password" class="block text-sm font-medium mb-1">
                            Password
                        </label>
                        <input
                            id="login_password"
                            name="login_password"
                            type="password"
                            required
                            class="w-full p-2 border border-[#E5E5E5] rounded-md"
                            placeholder="Password"
                            />

                        <div class="mt-1 text-right">
                            <a href="#" onclick="openPopup(); return false;"
                               class="text-[#2F5D50] text-sm font-medium">
                                Forgot Password?
                            </a>
                        </div>
                    </div>

                    <!-- LOGIN BUTTON -->
                    <button type="submit"
                            class="w-full bg-[#2F5D50] hover:bg-[#24483E] text-white p-2 rounded-md font-medium">
                        Login
                    </button>

                    <%-- Display error message if exists --%>
                    <% if (request.getAttribute("errorMessage") != null) {%>
                    <div class="mt-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
                        <%= request.getAttribute("errorMessage")%>
                    </div>
                    <% }%>

                    <!-- Register link -->
                    <div class="mt-6 text-center">
                        <p class="text-gray-600">
                            Not registered yet?
                            <a href="register.jsp" class="text-[#2F5D50] font-semibold hover:underline ml-1">
                                Create an account
                            </a>
                        </p>
                    </div>

                </form>
            </div>
        </div>

        <!-- POPUP RESET PASSWORD -->
        <div id="popup"
             class="hidden fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
            <div class="bg-white p-6 rounded-xl shadow-lg w-full max-w-sm">

                <!-- Header -->
                <h2 class="text-xl font-semibold mb-2 text-center text-[#2B2B2B]">
                    Reset Password
                </h2>

                <p class="text-sm text-gray-500 mb-4 text-center">
                    *For testing only: you may enter any random email.*
                </p>


                <!-- Divider line -->
                <hr class="border-[#E5E5E5] mb-4">

                <!-- Radio buttons: Login As -->
                <fieldset class="mb-4">
                    <legend class="block mb-2 font-medium text-[#2B2B2B]">Account Type</legend>
                    <div class="flex gap-4">
                        <label class="inline-flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="role" value="admin" checked class="cursor-pointer"/>
                            <span>Admin</span>
                        </label>
                        <label class="inline-flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="role" value="shelter" class="cursor-pointer"/>
                            <span>Shelter</span>
                        </label>
                        <label class="inline-flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="role" value="adopter" class="cursor-pointer"/>
                            <span>Adopter</span>
                        </label>
                    </div>
                </fieldset>

                <!-- Email input -->
                <input id="reset_email" type="email"
                       placeholder="Enter your email"
                       class="w-full p-2 border border-[#E5E5E5] rounded-md mb-4 focus:outline-none focus:ring-2 focus:ring-[#2F5D50]" />

                <!-- Buttons -->
                <button onclick="submitReset()"
                        class="w-full bg-[#6DBF89] hover:bg-[#57A677] text-white p-3 rounded-md font-medium mb-2 transition-colors">
                    Submit
                </button>

                <button onclick="closePopup()"
                        class="w-full bg-[#E5E5E5] hover:bg-[#D6D6D6] text-[#2B2B2B] p-3 rounded-md font-medium transition-colors">
                    Cancel
                </button>
            </div>
        </div>


        <script>
            // Update radio buttons to update hidden input
            document.addEventListener('DOMContentLoaded', function () {
                const roleRadios = document.querySelectorAll('input[name="role"]');
                const roleInput = document.getElementById('roleInput');

                roleRadios.forEach(radio => {
                    radio.addEventListener('change', function () {
                        roleInput.value = this.value;
                    });
                });

                // Update reset popup role selection
                const resetRoleRadios = document.querySelectorAll('#popup input[name="role"]');
                const resetRoleInput = document.createElement('input');
                resetRoleInput.type = 'hidden';
                resetRoleInput.name = 'reset_role';
                resetRoleInput.id = 'resetRoleInput';
                resetRoleInput.value = 'admin';
                document.querySelector('#popup form').appendChild(resetRoleInput);

                resetRoleRadios.forEach(radio => {
                    radio.addEventListener('change', function () {
                        resetRoleInput.value = this.value;
                    });
                });
            });

            // Remove the old onLogin function since we're using form submission
            function openPopup() {
                document.getElementById("popup").classList.remove("hidden");
            }

            function closePopup() {
                document.getElementById("popup").classList.add("hidden");
            }

            function submitReset() {
                const email = document.getElementById("reset_email").value;
                if (!email) {
                    alert("Please enter your email");
                    return;
                }
                // You can implement forgot password functionality later
                alert("Password reset functionality will be implemented soon.");
                closePopup();
            }
        </script>

    </body>
</html>