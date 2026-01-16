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

                <!-- ========== TAMBAH CODE INI ========== -->
                <%
                    String error = request.getParameter("error");
                    String message = request.getParameter("message");

                    if (error != null && !error.isEmpty()) {
                %>
                <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
                    <p class="text-red-600 text-sm">
                        <%= error.replace("_", " ")%>
                    </p>
                </div>
                <%
                    }

                    if (message != null && !message.isEmpty()) {
                %>
                <div class="mb-4 p-3 bg-green-50 border border-green-200 rounded-md">
                    <p class="text-green-600 text-sm">
                        <%= message.replace("_", " ")%>
                    </p>
                </div>
                <%
                    }
                %>
                <!-- ========== END TAMBAH CODE ========== -->

                <!-- ... kod sebelumnya ... -->

                <!-- GANTI FORM YANG LAMA DENGAN INI: -->
                <form action="AuthServlet" method="POST" class="space-y-4">
                    <!-- Hidden input untuk action -->
                    <input type="hidden" name="action" value="login">

                    <!-- roles -->
                    <fieldset class="mb-4">
                        <legend class="block mb-2 font-medium">Login As</legend>
                        <div class="flex gap-4">
                            <label class="inline-flex items-center gap-2">
                                <input type="radio" name="role" value="admin" required />
                                <span>Admin</span>
                            </label>
                            <label class="inline-flex items-center gap-2">
                                <input type="radio" name="role" value="shelter" required />
                                <span>Shelter</span>
                            </label>
                            <label class="inline-flex items-center gap-2">
                                <input type="radio" name="role" value="adopter" required />
                                <span>Adopter</span>
                            </label>
                        </div>
                    </fieldset>

                    <div>
                        <label for="email" class="block text-sm font-medium mb-1">
                            Email
                        </label>
                        <input
                            id="email"
                            name="email"
                            type="email"
                            required
                            class="w-full p-2 border border-[#E5E5E5] rounded-md"
                            placeholder="you@example.com"
                            />
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-medium mb-1">
                            Password
                        </label>
                        <input
                            id="password"
                            name="password"
                            type="password"
                            required
                            class="w-full p-2 border border-[#E5E5E5] rounded-md"
                            placeholder="Password"
                            />

                        <div class="mt-1 text-right">
                            <a href="#" onclick="openPopup(); return false;"
                               class="text-[#2F5D50] text-sm font-medium hover:underline underline-offset-4">
                                Forgot Password?
                            </a>
                        </div>
                    </div>

                    <!-- LOGIN BUTTON -->
                    <button type="submit"
                            class="w-full bg-[#2F5D50] hover:bg-[#24483E] text-white p-2 rounded-md font-medium">
                        Login
                    </button>

                    <div class="flex items-center justify-between mt-2 text-sm">
                        <p>
                            Don't have an account?
                            <a href="register.jsp" class="text-[#2F5D50] font-semibold hover:underline underline-offset-4">
                                Register here
                            </a>
                        </p>
                    </div>
                </form>

                <!-- ... kod seterusnya ... -->
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

            // ========== UPDATE INI SAHAJA ==========
            function submitReset() {
                const email = document.getElementById("reset_email").value;
                const role = document.querySelector('#popup input[name="role"]:checked').value;

                if (!email) {
                    alert("Please enter your email");
                    return;
                }

                // Create hidden form to submit to AuthServlet
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = 'AuthServlet';

                // Action parameter
                const actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = 'requestReset';
                form.appendChild(actionInput);

                // Email parameter
                const emailInput = document.createElement('input');
                emailInput.type = 'hidden';
                emailInput.name = 'email';
                emailInput.value = email;
                form.appendChild(emailInput);

                // Role parameter
                const roleInput = document.createElement('input');
                roleInput.type = 'hidden';
                roleInput.name = 'role';
                roleInput.value = role;
                form.appendChild(roleInput);

                // Add form to page and submit
                document.body.appendChild(form);
                form.submit();

                // Show loading in popup
                const submitBtn = document.querySelector('#popup button[onclick="submitReset()"]');
                if (submitBtn) {
                    submitBtn.innerHTML = 'Sending...';
                    submitBtn.disabled = true;
                }
            }
            // ========== END UPDATE ==========
        </script>

    </body>
</html>
