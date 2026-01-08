<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <script src="https://cdn.tailwindcss.com"></script>
        <title>Reset Password</title>
        <style>
            .error-message { 
                color: #dc2626; 
                font-size: 0.875rem; 
                margin-top: 0.25rem; 
            }
        </style>
    </head>
    <body class="bg-[#F6F3E7] flex items-center justify-center min-h-screen p-4 text-sm font-sans text-[#2B2B2B]">

        <%
            // Get token and error from URL
            String token = request.getParameter("token");
            String error = request.getParameter("error");

            // If no token, redirect to login
            if (token == null || token.trim().isEmpty()) {
                response.sendRedirect("login.jsp?error=Invalid_reset_link");
                return;
            }
        %>

        <div class="bg-white p-6 md:p-8 rounded-xl shadow-xl w-full max-w-md">
            <!-- Header -->
            <h1 class="text-2xl font-bold mb-6 text-center pb-2 border-b border-[#E5E5E5]">
                Reset Password
            </h1>

            <!-- Error Message (if any) -->
            <% if (error != null && !error.isEmpty()) {%>
            <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
                <p class="text-red-600 text-sm">
                    <%= error.replace("_", " ")%>
                </p>
            </div>
            <% }%>

            <!-- Reset Password Form -->
            <form id="resetForm" action="AuthServlet" method="POST" class="flex flex-col gap-4">

                <!-- Hidden fields -->
                <input type="hidden" name="action" value="resetPassword">
                <input type="hidden" name="token" value="<%= token%>">

                <!-- New Password -->
                <input id="new_password" name="newPassword" type="password" 
                       required minlength="6"
                       class="w-full p-3 border border-[#E5E5E5] rounded-md 
                       focus:outline-none focus:ring-2 focus:ring-[#2F5D50]"
                       placeholder="New Password (min 6 characters)"/>

                <!-- Confirm Password -->
                <input id="confirm_password" name="confirmPassword" type="password" 
                       required
                       class="w-full p-3 border border-[#E5E5E5] rounded-md 
                       focus:outline-none focus:ring-2 focus:ring-[#2F5D50]"
                       placeholder="Confirm Password"/>

                <!-- Password Error Message -->
                <div id="passwordError" class="error-message hidden"></div>

                <!-- Submit Button -->
                <button type="submit" id="resetBtn"
                        class="w-full bg-[#2F5D50] hover:bg-[#24483E] text-white 
                        p-3 rounded-md font-medium transition-colors">
                    Submit
                </button>

                <!-- Back to Login Link -->
                <div class="text-center pt-2">
                    <a href="login.jsp" 
                       class="text-[#2F5D50] text-sm font-medium hover:underline">
                        ← Back to Login
                    </a>
                </div>
            </form>
        </div>

        <script>
            document.addEventListener("DOMContentLoaded", function () {
                const form = document.getElementById('resetForm');
                const passwordError = document.getElementById('passwordError');
                const resetBtn = document.getElementById('resetBtn');

                form.addEventListener('submit', function (e) {
                    // Get values
                    const newPassword = document.getElementById('new_password').value;
                    const confirmPassword = document.getElementById('confirm_password').value;

                    // Clear previous error
                    passwordError.classList.add('hidden');
                    passwordError.textContent = '';

                    // Validate password length
                    if (newPassword.length < 6) {
                        e.preventDefault();
                        passwordError.textContent = 'Password must be at least 6 characters';
                        passwordError.classList.remove('hidden');
                        return false;
                    }

                    // Validate password match
                    if (newPassword !== confirmPassword) {
                        e.preventDefault();
                        passwordError.textContent = 'Passwords do not match';
                        passwordError.classList.remove('hidden');
                        return false;
                    }

                    // Show loading state
                    resetBtn.innerHTML = 'Processing...';
                    resetBtn.disabled = true;
                    resetBtn.classList.add('opacity-75', 'cursor-not-allowed');

                    return true;
                });
            });
        </script>
    </body>
</html>