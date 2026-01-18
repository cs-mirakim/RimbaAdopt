<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>

<%
    // Check if user is logged in and is admin
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isShelter(session)) {
        response.sendRedirect("index.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Shelter Dashboard - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
        <style>
            .banner-slide {
                display: none;
                animation: slideIn 0.5s ease-in-out;
            }
            .banner-slide.active {
                display: block;
            }
            @keyframes slideIn {
                from {
                    opacity: 0;
                    transform: translateX(100%);
                }
                to {
                    opacity: 1;
                    transform: translateX(0);
                }
            }
            .dot {
                height: 12px;
                width: 12px;
                margin: 0 4px;
                background-color: rgba(255, 255, 255, 0.5);
                border-radius: 50%;
                display: inline-block;
                transition: background-color 0.3s ease;
                cursor: pointer;
            }
            .dot.active {
                background-color: #FFFFFF;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Banner slideshow section -->
        <div class="p-4 pt-6 relative z-10 flex justify-center items-start">
            <div class="w-full" style="max-width: 1450px;">
                <div class="relative overflow-hidden rounded-xl shadow-lg">
                    <!-- Banner Images -->
                    <div class="banner-container relative" style="height: 400px;">
                        <div class="banner-slide active">
                            <img src="banner/banner1.jpg" alt="Banner 1" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner2.jpg" alt="Banner 2" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner3.jpg" alt="Banner 3" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner4.jpg" alt="Banner 4" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner5.jpg" alt="Banner 5" class="w-full h-full object-cover">
                        </div>

                        <!-- Navigation Arrows -->
                        <button onclick="changeSlide(-1)" class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                            </svg>
                        </button>
                        <button onclick="changeSlide(1)" class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                            </svg>
                        </button>
                    </div>

                    <!-- Dots Indicator -->
                    <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex items-center justify-center">
                        <span class="dot active" onclick="currentSlide(1)"></span>
                        <span class="dot" onclick="currentSlide(2)"></span>
                        <span class="dot" onclick="currentSlide(3)"></span>
                        <span class="dot" onclick="currentSlide(4)"></span>
                        <span class="dot" onclick="currentSlide(5)"></span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Dashboard Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Dashboard Title -->
                <div class="mb-8 pb-4 border-b border-gray-300">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Welcome Back, Shelter Manager!</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">
                        Here's an overview of your shelter's pets, adoption requests, and feedback.
                    </p>
                </div>

                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
                    <!-- Total Pets Listed -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium text-[#2F5D50] mb-1">Total Pets Listed</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]">20</p>
                    </div>

                    <!-- Pending Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-gray-400">
                        <p class="text-sm font-medium text-gray-700 mb-1">Pending Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]">8</p>
                    </div>

                    <!-- Approved Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <p class="text-sm font-medium text-[#57A677] mb-1">Approved Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]">12</p>
                    </div>

                    <!-- Rejected Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                        <p class="text-sm font-medium text-[#B84A4A] mb-1">Rejected Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]">3</p>
                    </div>

                    <!-- Cancelled Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <p class="text-sm font-medium text-[#C49A6C] mb-1">Cancelled Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]">1</p>
                    </div>
                </div>

                <!-- Request Overview Chart (Grouped Bar Chart) -->
                <div class="border border-[#E5E5E5] rounded-xl p-6 mb-8 shadow-sm">
                    <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Adoption Request Overview</h2>
                    <div class="relative" style="height: 400px;">
                        <canvas id="requestChart"></canvas>
                    </div>
                </div>

                <!-- Feedback Overview & Quick Links -->
                <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
                    <!-- Left area: Feedback Chart -->
                    <div class="lg:col-span-3 border border-[#E5E5E5] rounded-xl p-6 shadow-sm bg-white">
                        <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Shelter Feedback Overview</h2>
                        <div class="relative w-full h-72 sm:h-80 lg:h-[350px]">
                            <canvas id="feedbackChart" class="w-full h-full"></canvas>
                        </div>
                    </div>

                    <!-- Quick Links (right column) -->
                    <div class="lg:col-span-1 border border-[#E5E5E5] rounded-xl p-6 shadow-sm flex flex-col">
                        <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Quick Links</h2>

                        <div class="space-y-4">
                            <a href="manage_pets.jsp" class="flex items-center gap-3 p-4 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                                </svg>
                                <span class="text-sm font-medium">Manage Pets</span>
                            </a>

                            <a href="manage_request.jsp" class="flex items-center gap-3 p-4 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                                </svg>
                                <span class="text-sm font-medium">Manage Requests</span>
                            </a>
                        </div>
                    </div>
                </div>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
                            // Banner Slideshow
                            let slideIndex = 1;
                            let slideTimer;

                            function showSlides(n) {
                                let slides = document.getElementsByClassName("banner-slide");
                                let dots = document.getElementsByClassName("dot");

                                if (n > slides.length) {
                                    slideIndex = 1
                                }
                                if (n < 1) {
                                    slideIndex = slides.length
                                }

                                for (let i = 0; i < slides.length; i++) {
                                    slides[i].classList.remove("active");
                                }
                                for (let i = 0; i < dots.length; i++) {
                                    dots[i].classList.remove("active");
                                }

                                slides[slideIndex - 1].classList.add("active");
                                dots[slideIndex - 1].classList.add("active");
                            }

                            function changeSlide(n) {
                                clearInterval(slideTimer);
                                showSlides(slideIndex += n);
                                startAutoSlide();
                            }

                            function currentSlide(n) {
                                clearInterval(slideTimer);
                                showSlides(slideIndex = n);
                                startAutoSlide();
                            }

                            function startAutoSlide() {
                                slideTimer = setInterval(() => {
                                    slideIndex++;
                                    showSlides(slideIndex);
                                }, 5000);
                            }

                            // Initialize slideshow
                            showSlides(slideIndex);
                            startAutoSlide();

                            // Request Overview Chart (Grouped Bar Chart)
                            const reqCtx = document.getElementById('requestChart').getContext('2d');
                            const requestChart = new Chart(reqCtx, {
                                type: 'bar',
                                data: {
                                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                                    datasets: [
                                        {
                                            label: 'Approved',
                                            data: [1, 2, 1, 2, 1, 1, 1, 1, 1, 0, 1, 0],
                                            backgroundColor: '#6DBF89',
                                            borderColor: '#57A677',
                                            borderWidth: 1
                                        },
                                        {
                                            label: 'Pending',
                                            data: [1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0],
                                            backgroundColor: '#A3A3A3',
                                            borderColor: '#8A8A8A',
                                            borderWidth: 1
                                        },
                                        {
                                            label: 'Rejected',
                                            data: [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0],
                                            backgroundColor: '#B84A4A',
                                            borderColor: '#9A3A3A',
                                            borderWidth: 1
                                        },
                                        {
                                            label: 'Cancelled',
                                            data: [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
                                            backgroundColor: '#C49A6C',
                                            borderColor: '#A47A4C',
                                            borderWidth: 1
                                        }
                                    ]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        x: {
                                            grid: {
                                                display: false
                                            },
                                            title: {
                                                display: true,
                                                text: 'Month'
                                            }
                                        },
                                        y: {
                                            beginAtZero: true,
                                            ticks: {
                                                stepSize: 1,
                                                precision: 0
                                            },
                                            title: {
                                                display: true,
                                                text: 'Number of Requests'
                                            }
                                        }
                                    },
                                    plugins: {
                                        legend: {
                                            position: 'top'
                                        },
                                        tooltip: {
                                            mode: 'index',
                                            intersect: false
                                        }
                                    }
                                }
                            });

                            // Feedback Overview Chart (Line Chart - Average Rating per Month)
                            const feedbackCtx = document.getElementById('feedbackChart').getContext('2d');
                            const feedbackChart = new Chart(feedbackCtx, {
                                type: 'line',
                                data: {
                                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                                    datasets: [{
                                            label: 'Average Rating',
                                            data: [4.2, 4.5, 4.3, 4.7, 4.8, 4.6, 4.9, 4.7, 4.8, 4.9, 5.0, 4.8],
                                            borderColor: '#2F5D50',
                                            backgroundColor: 'rgba(47, 93, 80, 0.1)',
                                            borderWidth: 3,
                                            tension: 0.4,
                                            pointRadius: 6,
                                            pointBackgroundColor: '#2F5D50',
                                            pointBorderColor: '#FFFFFF',
                                            pointBorderWidth: 2,
                                            fill: true
                                        }]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        x: {
                                            grid: {
                                                display: false
                                            },
                                            title: {
                                                display: true,
                                                text: 'Month'
                                            }
                                        },
                                        y: {
                                            beginAtZero: false,
                                            min: 3.5,
                                            max: 5.2,
                                            ticks: {
                                                stepSize: 0.2,
                                                callback: function (value) {
                                                    return value.toFixed(1);
                                                }
                                            },
                                            title: {
                                                display: true,
                                                text: 'Average Rating (1-5)'
                                            }
                                        }
                                    },
                                    plugins: {
                                        legend: {
                                            position: 'top'
                                        },
                                        tooltip: {
                                            callbacks: {
                                                label: function (context) {
                                                    return `Rating: ${context.parsed.y.toFixed(1)}/5`;
                                                }
                                            }
                                        }
                                    }
                                }
                            });
        </script>

    </body>
</html>