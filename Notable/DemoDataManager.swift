//
//  DemoDataManager.swift
//  Notable
//
//  Created for demo mode functionality
//

import CoreData
import SwiftUI
import os.log

class DemoDataManager {
    static let shared = DemoDataManager()

    private let demoDataKey = "isDemoDataActive"

    var isDemoDataActive: Bool {
        get {
            UserDefaults.standard.bool(forKey: demoDataKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: demoDataKey)
        }
    }

    private init() {}

    // Create demo piles and entries
    func createDemoData(context: NSManagedObjectContext) {
        guard !isDemoDataActive else {
            os_log("⚠️ Demo data already active, skipping creation", log: .cloudKitSync, type: .info)
            return
        }

        os_log("🎬 Creating demo data...", log: .cloudKitSync, type: .info)

        context.perform {
            // Create three demo piles with different colors
            let workPile = self.createPile(
                context: context,
                name: "Work Projects",
                description: "Important work tasks and documentation",
                tag: "Safety Orange"
            )

            let personalPile = self.createPile(
                context: context,
                name: "Personal Ideas",
                description: "Creative thoughts and personal notes",
                tag: "Non Photo Blue"
            )

            let resourcesPile = self.createPile(
                context: context,
                name: "Resources",
                description: "Useful links and references",
                tag: "Raisin Black"
            )

            // Save piles first to ensure relationships are established
            do {
                try context.save()
                os_log("✅ Demo piles saved (3 piles)", log: .cloudKitSync, type: .info)
            } catch {
                os_log("❌ Error saving demo piles: %{public}@", log: .cloudKitSync, type: .error, error.localizedDescription)
                return
            }

            // Add entries to Work Projects pile (spread over ~60 days)
            self.createTextEntry(
                context: context,
                title: "Q4 Project Roadmap",
                content: """
                # Q4 Project Roadmap

                ## Objectives
                - Launch new mobile app features
                - Improve user onboarding experience
                - Optimize backend performance

                ## Timeline
                - **October**: Feature development
                - **November**: Testing & QA
                - **December**: Production release

                ## Key Metrics
                - User retention: +20%
                - Load time: -30%
                - Bug reports: -50%
                """,
                pile: workPile,
                daysAgo: 45
            )

            self.createTextEntry(
                context: context,
                title: "Meeting Notes - Sprint Planning",
                content: """
                # Sprint Planning Meeting

                **Date**: October 15, 2024
                **Attendees**: Team Alpha

                ## Decisions Made
                1. Focus on core features first
                2. Implement automated testing
                3. Weekly code review sessions

                ## Action Items
                - [ ] Set up CI/CD pipeline
                - [ ] Create design mockups
                - [ ] Schedule user interviews
                """,
                pile: workPile,
                daysAgo: 12
            )

            self.createTextEntry(
                context: context,
                title: "Code Review Checklist",
                content: """
                # Code Review Checklist

                - Code follows style guidelines
                - All tests pass
                - No security vulnerabilities
                - Documentation updated
                - Performance considerations addressed
                - Edge cases handled
                - Error handling implemented
                """,
                pile: workPile,
                daysAgo: 0
            )

            // Add entries to Personal Ideas pile
            self.createTextEntry(
                context: context,
                title: "App Idea: Recipe Organizer",
                content: """
                # Recipe Organizer App

                A smart recipe app that helps you:
                - Save recipes from any website
                - Generate shopping lists automatically
                - Suggest meals based on available ingredients
                - Track nutrition information

                **Tech Stack**
                - SwiftUI for UI
                - CoreData for storage
                - Vision framework for recipe scanning
                - HealthKit integration
                """,
                pile: personalPile,
                daysAgo: 1
            )

            self.createTextEntry(
                context: context,
                title: "Weekend Project Ideas",
                content: """
                # Weekend Hacking Projects

                1. **Habit Tracker**
                   - Simple, beautiful UI
                   - Daily reminders
                   - Progress visualization

                2. **Weather Poetry**
                   - Generate poems based on weather
                   - Use OpenAI API
                   - Beautiful typography

                3. **Music Practice Log**
                   - Track practice sessions
                   - Set goals
                   - Record progress
                """,
                pile: personalPile,
                daysAgo: 2
            )

            self.createTextEntry(
                context: context,
                title: "Book Notes: Atomic Habits",
                content: """
                # Atomic Habits - James Clear

                ## Key Takeaways

                > "You do not rise to the level of your goals. You fall to the level of your systems."

                ### The Four Laws
                1. **Make it Obvious** - Design your environment
                2. **Make it Attractive** - Bundle habits with things you enjoy
                3. **Make it Easy** - Reduce friction
                4. **Make it Satisfying** - Track your progress

                ### Habit Stacking
                After [CURRENT HABIT], I will [NEW HABIT]
                """,
                pile: personalPile,
                daysAgo: 3
            )

            // Add entries to Resources pile
            self.createLinkEntry(
                context: context,
                url: "https://developer.apple.com/documentation/swiftui",
                pile: resourcesPile,
                daysAgo: 4
            )

            self.createLinkEntry(
                context: context,
                url: "https://github.com",
                pile: resourcesPile,
                daysAgo: 5
            )

            self.createTextEntry(
                context: context,
                title: "SwiftUI Best Practices",
                content: """
                # SwiftUI Best Practices

                ## Performance
                - Use `@State` for view-local state
                - Use `@StateObject` for reference types
                - Avoid heavy computations in body
                - Use `LazyVStack` for long lists

                ## Code Organization
                - Extract complex views into subviews
                - Use ViewModifiers for reusable styling
                - Keep view files under 200 lines

                ## State Management
                - Single source of truth
                - Unidirectional data flow
                - Use environment for shared data
                """,
                pile: resourcesPile,
                daysAgo: 6
            )

            // Add more entries to Work Projects pile
            self.createTextEntry(
                context: context,
                title: "API Documentation",
                content: """
                # REST API Endpoints

                ## Authentication
                `POST /api/auth/login`
                - Returns JWT token
                - Expires in 24 hours

                ## User Management
                `GET /api/users/{id}`
                `PUT /api/users/{id}`
                `DELETE /api/users/{id}`

                ## Best Practices
                - Always validate input
                - Use rate limiting
                - Log all requests
                - Return proper status codes
                """,
                pile: workPile,
                daysAgo: 7
            )

            self.createLinkEntry(
                context: context,
                url: "https://stackoverflow.com",
                pile: workPile,
                daysAgo: 8
            )

            self.createTextEntry(
                context: context,
                title: "Bug Report Template",
                content: """
                # Bug Report

                ## Description
                [Clear description of the bug]

                ## Steps to Reproduce
                1. Step one
                2. Step two
                3. Step three

                ## Expected Behavior
                [What should happen]

                ## Actual Behavior
                [What actually happens]

                ## Environment
                - OS:
                - Version:
                - Device:
                """,
                pile: workPile,
                daysAgo: 9
            )

            // Add code examples to Work Projects pile
            self.createCodeEntry(
                context: context,
                title: "SwiftUI View Example",
                content: """
                import SwiftUI

                struct ContentView: View {
                    @State private var isExpanded = false
                    @State private var username = ""

                    var body: some View {
                        NavigationView {
                            Form {
                                Section("User Information") {
                                    TextField("Username", text: $username)
                                        .textContentType(.username)

                                    Toggle("Show Details", isOn: $isExpanded)
                                }

                                if isExpanded {
                                    Section("Additional Options") {
                                        Button("Save Profile") {
                                            saveUserProfile()
                                        }
                                        .disabled(username.isEmpty)
                                    }
                                }
                            }
                            .navigationTitle("Settings")
                        }
                    }

                    private func saveUserProfile() {
                        // Save logic here
                        print("Saving profile for: \\(username)")
                    }
                }
                """,
                language: "swift",
                pile: workPile,
                daysAgo: 10
            )

            self.createCodeEntry(
                context: context,
                title: "API Response Handler",
                content: """
                async function fetchUserData(userId) {
                    try {
                        const response = await fetch(`/api/users/${userId}`);

                        if (!response.ok) {
                            throw new Error(`HTTP error! status: ${response.status}`);
                        }

                        const data = await response.json();

                        return {
                            success: true,
                            user: {
                                id: data.id,
                                name: data.name,
                                email: data.email,
                                createdAt: new Date(data.created_at)
                            }
                        };
                    } catch (error) {
                        console.error('Error fetching user:', error);
                        return {
                            success: false,
                            error: error.message
                        };
                    }
                }

                // Usage
                const result = await fetchUserData('123');
                if (result.success) {
                    console.log('User loaded:', result.user.name);
                } else {
                    console.error('Failed to load user:', result.error);
                }
                """,
                language: "javascript",
                pile: workPile,
                daysAgo: 11
            )

            // Add more entries to Personal Ideas pile
            self.createTextEntry(
                context: context,
                title: "Travel Bucket List",
                content: """
                # Places to Visit

                ## Asia
                - 🇯🇵 Tokyo, Japan - Cherry blossoms in spring
                - 🇹🇭 Bangkok, Thailand - Street food paradise
                - 🇰🇷 Seoul, Korea - Modern tech meets tradition

                ## Europe
                - 🇮🇹 Rome, Italy - Ancient history
                - 🇫🇷 Paris, France - Art and culture
                - 🇬🇷 Santorini, Greece - Stunning sunsets

                ## Americas
                - 🇵🇪 Machu Picchu, Peru - Incan ruins
                - 🇨🇦 Banff, Canada - Mountain paradise
                """,
                pile: personalPile,
                daysAgo: 12
            )

            self.createTextEntry(
                context: context,
                title: "Workout Routine",
                content: """
                # Weekly Fitness Plan

                ## Monday - Upper Body
                - Push-ups: 3 sets of 15
                - Pull-ups: 3 sets of 10
                - Dumbbell press: 3 sets of 12

                ## Wednesday - Lower Body
                - Squats: 3 sets of 15
                - Lunges: 3 sets of 12 each leg
                - Calf raises: 3 sets of 20

                ## Friday - Core
                - Planks: 3 sets of 60 seconds
                - Crunches: 3 sets of 20
                - Leg raises: 3 sets of 15
                """,
                pile: personalPile,
                daysAgo: 13
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.reddit.com",
                pile: personalPile,
                daysAgo: 14
            )

            self.createTextEntry(
                context: context,
                title: "Recipe: Pasta Carbonara",
                content: """
                # Classic Pasta Carbonara

                ## Ingredients
                - 400g spaghetti
                - 200g pancetta or guanciale
                - 4 egg yolks
                - 100g Pecorino Romano
                - Black pepper
                - Salt

                ## Instructions
                1. Cook pasta in salted boiling water
                2. Crisp pancetta in a pan
                3. Mix egg yolks with grated cheese
                4. Toss hot pasta with pancetta
                5. Remove from heat, add egg mixture
                6. Toss quickly, add pasta water if needed
                7. Serve with extra cheese and pepper

                **Pro tip**: The heat from the pasta cooks the eggs!
                """,
                pile: personalPile,
                daysAgo: 15
            )

            // Add code examples to Personal Ideas pile
            self.createCodeEntry(
                context: context,
                title: "Habit Tracker Prototype",
                content: """
                class HabitTracker {
                    constructor() {
                        this.habits = [];
                    }

                    addHabit(name, frequency = 'daily') {
                        const habit = {
                            id: Date.now(),
                            name,
                            frequency,
                            streak: 0,
                            completions: []
                        };
                        this.habits.push(habit);
                        return habit;
                    }

                    completeHabit(habitId) {
                        const habit = this.habits.find(h => h.id === habitId);
                        if (!habit) return false;

                        const today = new Date().toDateString();
                        if (!habit.completions.includes(today)) {
                            habit.completions.push(today);
                            this.updateStreak(habit);
                        }
                        return true;
                    }

                    updateStreak(habit) {
                        const dates = habit.completions.map(d => new Date(d));
                        dates.sort((a, b) => b - a);

                        let streak = 0;
                        let currentDate = new Date();

                        for (const date of dates) {
                            const daysDiff = Math.floor((currentDate - date) / (1000 * 60 * 60 * 24));
                            if (daysDiff <= streak + 1) {
                                streak++;
                                currentDate = date;
                            } else {
                                break;
                            }
                        }

                        habit.streak = streak;
                    }

                    getStats(habitId) {
                        const habit = this.habits.find(h => h.id === habitId);
                        return {
                            totalCompletions: habit.completions.length,
                            currentStreak: habit.streak,
                            completionRate: this.calculateRate(habit)
                        };
                    }

                    calculateRate(habit) {
                        const daysSinceStart = 30; // simplified
                        return (habit.completions.length / daysSinceStart * 100).toFixed(1);
                    }
                }
                """,
                language: "javascript",
                pile: personalPile,
                daysAgo: 16
            )

            // Add more entries to Resources pile
            self.createTextEntry(
                context: context,
                title: "Keyboard Shortcuts",
                content: """
                # Essential Mac Shortcuts

                ## Navigation
                - `⌘ + Tab` - Switch apps
                - `⌘ + Space` - Spotlight search
                - `⌘ + W` - Close window
                - `⌘ + Q` - Quit app

                ## Text Editing
                - `⌘ + Z` - Undo
                - `⌘ + Shift + Z` - Redo
                - `⌘ + C/V/X` - Copy/Paste/Cut
                - `⌥ + ←/→` - Move by word

                ## Screenshots
                - `⌘ + Shift + 3` - Full screen
                - `⌘ + Shift + 4` - Selection
                - `⌘ + Shift + 5` - Screenshot tools
                """,
                pile: resourcesPile,
                daysAgo: 17
            )

            self.createTextEntry(
                context: context,
                title: "Git Commands Cheat Sheet",
                content: """
                # Git Essentials

                ## Basic Commands
                ```bash
                git init
                git clone <url>
                git status
                git add .
                git commit -m "message"
                git push origin main
                ```

                ## Branching
                ```bash
                git branch feature-name
                git checkout feature-name
                git merge feature-name
                git branch -d feature-name
                ```

                ## Undo Changes
                ```bash
                git reset --hard HEAD
                git revert <commit>
                git checkout -- <file>
                ```
                """,
                pile: resourcesPile,
                daysAgo: 18
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.hackernews.com",
                pile: resourcesPile,
                daysAgo: 19
            )

            self.createTextEntry(
                context: context,
                title: "Design Resources",
                content: """
                # Useful Design Tools & Sites

                ## Color Palettes
                - Coolors.co - Color scheme generator
                - Adobe Color - Color wheel tool
                - Paletton - Color scheme designer

                ## Icons & Illustrations
                - SF Symbols - Apple's icon library
                - Heroicons - Beautiful hand-crafted SVG icons
                - unDraw - Open-source illustrations

                ## Typography
                - Google Fonts - Free fonts
                - Font Pair - Font pairing tool
                - Type Scale - Visual type scale calculator

                ## Inspiration
                - Dribbble - Design showcase
                - Behance - Creative work
                - Awwwards - Web design awards
                """,
                pile: resourcesPile,
                daysAgo: 20
            )

            self.createTextEntry(
                context: context,
                title: "SQL Query Examples",
                content: """
                # Common SQL Queries

                ## Select with Joins
                ```sql
                SELECT users.name, orders.total
                FROM users
                INNER JOIN orders ON users.id = orders.user_id
                WHERE orders.date > '2024-01-01';
                ```

                ## Aggregate Functions
                ```sql
                SELECT COUNT(*), AVG(price), MAX(price)
                FROM products
                GROUP BY category
                HAVING COUNT(*) > 10;
                ```

                ## Subqueries
                ```sql
                SELECT name FROM users
                WHERE id IN (
                    SELECT user_id FROM orders
                    WHERE total > 100
                );
                ```
                """,
                pile: resourcesPile,
                daysAgo: 21
            )

            self.createTextEntry(
                context: context,
                title: "Security Best Practices",
                content: """
                # Application Security Checklist

                ## Authentication
                - Use strong password hashing (bcrypt, Argon2)
                - Implement 2FA/MFA
                - Secure session management
                - Token expiration policies

                ## Data Protection
                - Encrypt sensitive data at rest
                - Use HTTPS everywhere
                - Sanitize user inputs
                - Prevent SQL injection

                ## Access Control
                - Principle of least privilege
                - Role-based access control
                - Regular permission audits
                - API rate limiting
                """,
                pile: workPile,
                daysAgo: 22
            )

            self.createTextEntry(
                context: context,
                title: "Performance Optimization Tips",
                content: """
                # App Performance Guide

                ## Memory Management
                - Avoid retain cycles
                - Use weak/unowned references
                - Profile with Instruments
                - Monitor memory footprint

                ## Network Optimization
                - Cache responses
                - Batch requests
                - Use compression
                - Implement pagination

                ## UI Performance
                - Lazy loading
                - Image optimization
                - Reduce view hierarchy
                - Avoid blocking main thread
                """,
                pile: workPile,
                daysAgo: 23
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.medium.com",
                pile: resourcesPile,
                daysAgo: 24
            )

            // Add placeholder images to different piles
            if let imageData1 = self.createPlaceholderImage(text: "📱 App\nMockup", color: .systemBlue) {
                self.createImageEntry(context: context, image: imageData1, pile: workPile, daysAgo: 25)
            }

            if let imageData2 = self.createPlaceholderImage(text: "🌄 Vacation\nPhoto", color: .systemOrange) {
                self.createImageEntry(context: context, image: imageData2, pile: personalPile, daysAgo: 27)
            }

            if let imageData3 = self.createPlaceholderImage(text: "🎨 Design\nReference", color: .systemPurple) {
                self.createImageEntry(context: context, image: imageData3, pile: resourcesPile, daysAgo: 29)
            }

            if let imageData4 = self.createPlaceholderImage(text: "📊 Dashboard\nWireframe", color: .systemTeal) {
                self.createImageEntry(context: context, image: imageData4, pile: workPile, daysAgo: 31)
            }

            self.createTextEntry(
                context: context,
                title: "Daily Reflection",
                content: """
                # Today's Thoughts

                ## Wins
                - Completed the new feature implementation
                - Had a great conversation with the team
                - Learned something new about SwiftUI

                ## Challenges
                - Debugging that tricky memory leak
                - Time management could be better

                ## Tomorrow's Goals
                - Start on the API refactor
                - Review pull requests
                - Update documentation
                """,
                pile: personalPile,
                daysAgo: 25
            )

            self.createTextEntry(
                context: context,
                title: "Reading List",
                content: """
                # Books to Read

                ## Currently Reading
                - "Designing Data-Intensive Applications" by Martin Kleppmann

                ## Queue
                - "The Pragmatic Programmer" by Hunt & Thomas
                - "Clean Code" by Robert Martin
                - "Refactoring" by Martin Fowler
                - "System Design Interview" by Alex Xu

                ## Completed
                - ✅ "Atomic Habits" by James Clear
                - ✅ "Deep Work" by Cal Newport
                """,
                pile: personalPile,
                daysAgo: 26
            )

            self.createTextEntry(
                context: context,
                title: "Learning Goals 2024",
                content: """
                # Skills to Develop

                ## Technical
                - [ ] Master SwiftUI animations
                - [ ] Learn Combine framework
                - [ ] Explore machine learning basics
                - [ ] Improve algorithm knowledge

                ## Soft Skills
                - [ ] Public speaking
                - [ ] Technical writing
                - [ ] Team leadership
                - [ ] Mentoring

                ## Languages
                - [ ] Improve Spanish
                - [ ] Start learning Japanese
                """,
                pile: personalPile,
                daysAgo: 27
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.netflix.com",
                pile: personalPile,
                daysAgo: 28
            )

            if let imageData5 = self.createPlaceholderImage(text: "🎬 Movie\nPoster", color: .systemRed) {
                self.createImageEntry(context: context, image: imageData5, pile: personalPile, daysAgo: 33)
            }

            if let imageData6 = self.createPlaceholderImage(text: "🏋️ Workout\nProgress", color: .systemGreen) {
                self.createImageEntry(context: context, image: imageData6, pile: personalPile, daysAgo: 35)
            }

            self.createTextEntry(
                context: context,
                title: "Regex Cheat Sheet",
                content: """
                # Regular Expressions

                ## Basic Patterns
                - `.` - Any character
                - `\\d` - Digit
                - `\\w` - Word character
                - `\\s` - Whitespace
                - `^` - Start of line
                - `$` - End of line

                ## Quantifiers
                - `*` - 0 or more
                - `+` - 1 or more
                - `?` - 0 or 1
                - `{n}` - Exactly n
                - `{n,}` - n or more
                - `{n,m}` - Between n and m

                ## Examples
                - Email: `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}`
                - URL: `https?://[\\w.-]+\\.[a-zA-Z]{2,}`
                - Phone: `\\d{3}-\\d{3}-\\d{4}`
                """,
                pile: resourcesPile,
                daysAgo: 29
            )

            self.createTextEntry(
                context: context,
                title: "Docker Commands",
                content: """
                # Docker Quick Reference

                ## Container Management
                ```bash
                docker run -d -p 8080:80 nginx
                docker ps
                docker stop <container_id>
                docker rm <container_id>
                docker logs <container_id>
                docker exec -it <container_id> bash
                ```

                ## Image Management
                ```bash
                docker images
                docker pull ubuntu
                docker build -t myapp .
                docker rmi <image_id>
                docker push myapp:latest
                ```

                ## Docker Compose
                ```bash
                docker-compose up -d
                docker-compose down
                docker-compose logs -f
                ```
                """,
                pile: resourcesPile,
                daysAgo: 30
            )

            if let imageData7 = self.createPlaceholderImage(text: "📐 Architecture\nDiagram", color: .systemIndigo) {
                self.createImageEntry(context: context, image: imageData7, pile: resourcesPile, daysAgo: 37)
            }

            if let imageData8 = self.createPlaceholderImage(text: "🎯 Sprint\nBoard", color: .systemPink) {
                self.createImageEntry(context: context, image: imageData8, pile: workPile, daysAgo: 39)
            }

            self.createTextEntry(
                context: context,
                title: "Product Requirements",
                content: """
                # Feature Specification: User Dashboard

                ## Overview
                A personalized dashboard showing user activity and statistics.

                ## Requirements
                - Display recent activity (last 30 days)
                - Show key metrics (logins, actions, achievements)
                - Interactive charts and graphs
                - Export data functionality
                - Mobile responsive design

                ## User Stories
                - As a user, I want to see my activity at a glance
                - As a user, I want to track my progress over time
                - As a user, I want to export my data

                ## Acceptance Criteria
                - Dashboard loads in < 2 seconds
                - Charts are interactive and update in real-time
                - All data is accurate and up-to-date
                """,
                pile: workPile,
                daysAgo: 31
            )

            self.createTextEntry(
                context: context,
                title: "Team Onboarding Guide",
                content: """
                # New Developer Onboarding

                ## Week 1: Setup
                - [ ] Get laptop and accounts
                - [ ] Clone repositories
                - [ ] Set up dev environment
                - [ ] Meet the team
                - [ ] Read documentation

                ## Week 2: Learning
                - [ ] Complete code walkthrough
                - [ ] Understand architecture
                - [ ] Review coding standards
                - [ ] Shadow senior dev

                ## Week 3: Contributing
                - [ ] Pick first issue
                - [ ] Submit first PR
                - [ ] Participate in code review
                - [ ] Attend sprint planning

                ## Resources
                - Architecture docs
                - Style guide
                - Slack channels
                - Team calendar
                """,
                pile: workPile,
                daysAgo: 32
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.notion.so",
                pile: workPile,
                daysAgo: 33
            )

            self.createTextEntry(
                context: context,
                title: "CSS Flexbox Guide",
                content: """
                # Flexbox Cheat Sheet

                ## Container Properties
                ```css
                display: flex;
                flex-direction: row | column;
                justify-content: center | space-between | space-around;
                align-items: center | flex-start | flex-end | stretch;
                flex-wrap: wrap | nowrap;
                gap: 10px;
                ```

                ## Item Properties
                ```css
                flex: 1;
                flex-grow: 1;
                flex-shrink: 0;
                flex-basis: auto;
                align-self: center;
                order: 1;
                ```

                ## Common Patterns
                - Center content: `justify-content: center; align-items: center;`
                - Space between: `justify-content: space-between;`
                - Responsive grid: `flex-wrap: wrap;`
                """,
                pile: resourcesPile,
                daysAgo: 34
            )

            self.createTextEntry(
                context: context,
                title: "Meditation Practice",
                content: """
                # Daily Meditation Routine

                ## Morning (10 minutes)
                1. Find comfortable position
                2. Focus on breath
                3. Notice thoughts without judgment
                4. Return to breath
                5. Set intention for the day

                ## Evening (5 minutes)
                1. Reflect on the day
                2. Practice gratitude
                3. Body scan relaxation
                4. Let go of tensions

                ## Tips
                - Start small, be consistent
                - Use guided meditations if helpful
                - Find a quiet space
                - Same time each day builds habit
                """,
                pile: personalPile,
                daysAgo: 35
            )

            self.createTextEntry(
                context: context,
                title: "Home Improvement Ideas",
                content: """
                # House Projects

                ## Immediate
                - Fix leaky faucet in bathroom
                - Paint bedroom walls
                - Replace old light fixtures
                - Organize garage

                ## This Year
                - Renovate kitchen backsplash
                - Install smart thermostat
                - Landscape backyard
                - Add storage solutions

                ## Dream Projects
                - Build home office
                - Create outdoor living space
                - Smart home integration
                - Solar panels
                """,
                pile: personalPile,
                daysAgo: 36
            )

            if let imageData9 = self.createPlaceholderImage(text: "🏠 Home\nDesign", color: .systemBrown) {
                self.createImageEntry(context: context, image: imageData9, pile: personalPile, daysAgo: 41)
            }

            self.createTextEntry(
                context: context,
                title: "Podcast Recommendations",
                content: """
                # Great Podcasts to Listen To

                ## Tech & Development
                - Syntax - Web development
                - Swift by Sundell - iOS development
                - The Changelog - Open source
                - Talk Python To Me - Python programming

                ## Business & Productivity
                - How I Built This - Entrepreneurship
                - Masters of Scale - Startup growth
                - Deep Questions - Cal Newport

                ## Science & Learning
                - Radiolab - Science stories
                - Hidden Brain - Psychology
                - 99% Invisible - Design
                """,
                pile: personalPile,
                daysAgo: 37
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.spotify.com",
                pile: personalPile,
                daysAgo: 38
            )

            self.createTextEntry(
                context: context,
                title: "Testing Strategies",
                content: """
                # Comprehensive Testing Guide

                ## Unit Tests
                - Test individual functions
                - Mock dependencies
                - Fast execution
                - High coverage of business logic

                ## Integration Tests
                - Test component interactions
                - Use real dependencies when possible
                - Verify data flow
                - API contract testing

                ## UI Tests
                - Test user workflows
                - Critical paths only
                - Run in CI/CD pipeline
                - Maintain test stability

                ## Test Pyramid
                - Many unit tests (70%)
                - Some integration tests (20%)
                - Few UI tests (10%)

                ## Best Practices
                - Write tests first (TDD)
                - Keep tests simple
                - One assertion per test
                - Descriptive test names
                """,
                pile: workPile,
                daysAgo: 39
            )

            self.createTextEntry(
                context: context,
                title: "CI/CD Pipeline Setup",
                content: """
                # Continuous Integration Configuration

                ## Pipeline Stages
                1. **Build** - Compile code
                2. **Test** - Run all tests
                3. **Lint** - Code quality checks
                4. **Security** - Vulnerability scanning
                5. **Deploy** - Push to staging/production

                ## GitHub Actions Example
                ```yaml
                name: CI
                on: [push, pull_request]
                jobs:
                  test:
                    runs-on: ubuntu-latest
                    steps:
                      - uses: actions/checkout@v2
                      - name: Run tests
                        run: npm test
                      - name: Build
                        run: npm run build
                ```

                ## Best Practices
                - Fast feedback (< 10 min)
                - Fail fast
                - Automated deployments
                - Rollback capability
                """,
                pile: workPile,
                daysAgo: 40
            )

            if let imageData10 = self.createPlaceholderImage(text: "🚀 Deploy\nPipeline", color: .systemCyan) {
                self.createImageEntry(context: context, image: imageData10, pile: workPile, daysAgo: 43)
            }

            self.createTextEntry(
                context: context,
                title: "Database Design Principles",
                content: """
                # Database Schema Best Practices

                ## Normalization
                - First Normal Form (1NF): Atomic values
                - Second Normal Form (2NF): No partial dependencies
                - Third Normal Form (3NF): No transitive dependencies

                ## Indexing Strategy
                - Index frequently queried columns
                - Composite indexes for multi-column queries
                - Monitor index usage and performance
                - Avoid over-indexing

                ## Performance Tips
                - Use appropriate data types
                - Denormalize when necessary
                - Partition large tables
                - Implement caching layer

                ## Security
                - Principle of least privilege
                - Parameterized queries
                - Encrypt sensitive data
                - Regular backups
                """,
                pile: workPile,
                daysAgo: 41
            )

            self.createTextEntry(
                context: context,
                title: "Microservices Architecture",
                content: """
                # Microservices Design Patterns

                ## Key Principles
                - Single responsibility
                - Decentralized data management
                - Independent deployment
                - Failure isolation

                ## Communication
                - REST APIs
                - Message queues (RabbitMQ, Kafka)
                - Service mesh (Istio)
                - API Gateway pattern

                ## Challenges
                - Distributed transactions
                - Service discovery
                - Monitoring and logging
                - Data consistency

                ## Tools
                - Docker & Kubernetes
                - Service mesh
                - Distributed tracing
                - Circuit breakers
                """,
                pile: workPile,
                daysAgo: 42
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.figma.com",
                pile: workPile,
                daysAgo: 43
            )

            if let imageData11 = self.createPlaceholderImage(text: "🗺️ User\nJourney", color: .systemMint) {
                self.createImageEntry(context: context, image: imageData11, pile: workPile, daysAgo: 45)
            }

            self.createTextEntry(
                context: context,
                title: "JavaScript ES6+ Features",
                content: """
                # Modern JavaScript

                ## Arrow Functions
                ```javascript
                const sum = (a, b) => a + b;
                const square = x => x * x;
                ```

                ## Destructuring
                ```javascript
                const { name, age } = person;
                const [first, second] = array;
                ```

                ## Spread & Rest
                ```javascript
                const merged = [...arr1, ...arr2];
                const { a, ...rest } = obj;
                ```

                ## Async/Await
                ```javascript
                async function fetchData() {
                  const response = await fetch(url);
                  const data = await response.json();
                  return data;
                }
                ```

                ## Template Literals
                ```javascript
                const message = `Hello ${name}!`;
                ```
                """,
                pile: resourcesPile,
                daysAgo: 44
            )

            self.createTextEntry(
                context: context,
                title: "Accessibility Guidelines",
                content: """
                # Web Accessibility (WCAG)

                ## Key Principles
                - Perceivable: Content can be perceived
                - Operable: Interface is operable
                - Understandable: Information is clear
                - Robust: Works with assistive tech

                ## Best Practices
                - Semantic HTML
                - ARIA labels when needed
                - Keyboard navigation
                - Sufficient color contrast
                - Alternative text for images
                - Captions for videos

                ## Testing
                - Screen reader testing
                - Keyboard-only navigation
                - Automated tools (axe, WAVE)
                - Manual testing

                ## Common Issues
                - Missing alt text
                - Poor color contrast
                - Non-semantic markup
                - Inaccessible forms
                """,
                pile: resourcesPile,
                daysAgo: 45
            )

            // Add code examples to Resources pile
            self.createCodeEntry(
                context: context,
                title: "Python Data Processing",
                content: """
                import pandas as pd
                import numpy as np
                from datetime import datetime

                def process_sales_data(filepath):
                    # Load CSV data
                    df = pd.read_csv(filepath)

                    # Clean and transform data
                    df['date'] = pd.to_datetime(df['date'])
                    df['total'] = df['quantity'] * df['price']

                    # Calculate statistics
                    summary = {
                        'total_sales': df['total'].sum(),
                        'avg_sale': df['total'].mean(),
                        'num_transactions': len(df),
                        'top_product': df.groupby('product')['total'].sum().idxmax()
                    }

                    # Group by date and calculate daily totals
                    daily_sales = df.groupby(df['date'].dt.date)['total'].sum()

                    return summary, daily_sales

                # Usage
                summary, daily = process_sales_data('sales_2024.csv')
                print(f"Total Sales: ${summary['total_sales']:,.2f}")
                print(f"Best Product: {summary['top_product']}")
                """,
                language: "python",
                pile: resourcesPile,
                daysAgo: 46
            )

            self.createCodeEntry(
                context: context,
                title: "React Component Example",
                content: """
                import React, { useState, useEffect } from 'react';

                function UserProfile({ userId }) {
                    const [user, setUser] = useState(null);
                    const [loading, setLoading] = useState(true);
                    const [error, setError] = useState(null);

                    useEffect(() => {
                        async function fetchUser() {
                            try {
                                const response = await fetch(`/api/users/${userId}`);
                                if (!response.ok) throw new Error('User not found');

                                const data = await response.json();
                                setUser(data);
                            } catch (err) {
                                setError(err.message);
                            } finally {
                                setLoading(false);
                            }
                        }

                        fetchUser();
                    }, [userId]);

                    if (loading) return <div className="spinner">Loading...</div>;
                    if (error) return <div className="error">Error: {error}</div>;

                    return (
                        <div className="profile">
                            <img src={user.avatar} alt={user.name} />
                            <h2>{user.name}</h2>
                            <p>{user.email}</p>
                            <button onClick={() => console.log('Edit profile')}>
                                Edit Profile
                            </button>
                        </div>
                    );
                }

                export default UserProfile;
                """,
                language: "javascript",
                pile: resourcesPile,
                daysAgo: 47
            )

            self.createCodeEntry(
                context: context,
                title: "SQL Query - User Analytics",
                content: """
                -- Get top 10 users by total purchases
                WITH user_totals AS (
                    SELECT
                        u.id,
                        u.name,
                        u.email,
                        COUNT(o.id) as order_count,
                        SUM(o.total) as total_spent,
                        AVG(o.total) as avg_order_value
                    FROM users u
                    LEFT JOIN orders o ON u.id = o.user_id
                    WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
                    GROUP BY u.id, u.name, u.email
                )
                SELECT
                    name,
                    email,
                    order_count,
                    ROUND(total_spent, 2) as total_spent,
                    ROUND(avg_order_value, 2) as avg_order_value,
                    CASE
                        WHEN total_spent > 1000 THEN 'VIP'
                        WHEN total_spent > 500 THEN 'Gold'
                        WHEN total_spent > 100 THEN 'Silver'
                        ELSE 'Bronze'
                    END as customer_tier
                FROM user_totals
                WHERE order_count > 0
                ORDER BY total_spent DESC
                LIMIT 10;
                """,
                language: "sql",
                pile: resourcesPile,
                daysAgo: 48
            )

            if let imageData12 = self.createPlaceholderImage(text: "♿️ A11y\nChecklist", color: .systemGreen) {
                self.createImageEntry(context: context, image: imageData12, pile: resourcesPile, daysAgo: 47)
            }

            self.createTextEntry(
                context: context,
                title: "Morning Routine",
                content: """
                # Ideal Morning Schedule

                ## 6:00 AM - Wake Up
                - No snooze button
                - Drink glass of water
                - Open curtains

                ## 6:15 AM - Exercise
                - 30 min workout or run
                - Stretch
                - Cold shower

                ## 7:00 AM - Breakfast
                - Healthy protein & fruit
                - Review daily goals
                - Read news/articles

                ## 7:45 AM - Deep Work
                - Most important task
                - No distractions
                - Flow state

                ## Benefits
                - Better energy levels
                - Improved focus
                - Sense of accomplishment
                - Consistent routine
                """,
                pile: personalPile,
                daysAgo: 49
            )

            self.createTextEntry(
                context: context,
                title: "Financial Goals",
                content: """
                # Money Management Plan

                ## Short Term (This Year)
                - [ ] Build 6-month emergency fund
                - [ ] Pay off credit card debt
                - [ ] Start investing 15% income
                - [ ] Track all expenses

                ## Medium Term (5 Years)
                - [ ] Save for home down payment
                - [ ] Increase retirement contributions
                - [ ] Build passive income stream
                - [ ] Max out retirement accounts

                ## Long Term (Retirement)
                - [ ] $2M retirement savings goal
                - [ ] Paid-off mortgage
                - [ ] Multiple income sources
                - [ ] Financial independence

                ## Monthly Budget
                - Housing: 30%
                - Savings: 20%
                - Food: 15%
                - Transportation: 10%
                - Other: 25%
                """,
                pile: personalPile,
                daysAgo: 50
            )

            self.createTextEntry(
                context: context,
                title: "Language Learning Tips",
                content: """
                # How to Learn a New Language

                ## Daily Practice
                - 30 minutes minimum
                - Consistency over intensity
                - Mix all four skills
                - Use spaced repetition

                ## Immersion Techniques
                - Watch shows with subtitles
                - Listen to podcasts
                - Read children's books
                - Think in target language

                ## Speaking Practice
                - Language exchange partners
                - Online tutors (italki)
                - Record yourself
                - Don't fear mistakes

                ## Resources
                - Duolingo - Vocabulary
                - Anki - Flashcards
                - HelloTalk - Practice
                - YouTube - Native content

                ## Milestones
                - Month 1: Basic phrases
                - Month 3: Simple conversations
                - Month 6: Intermediate level
                - Year 1: Conversational fluency
                """,
                pile: personalPile,
                daysAgo: 51
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.duolingo.com",
                pile: personalPile,
                daysAgo: 52
            )

            if let imageData13 = self.createPlaceholderImage(text: "🌍 Travel\nMap", color: .systemIndigo) {
                self.createImageEntry(context: context, image: imageData13, pile: personalPile, daysAgo: 49)
            }

            if let imageData14 = self.createPlaceholderImage(text: "💰 Budget\nChart", color: .systemMint) {
                self.createImageEntry(context: context, image: imageData14, pile: personalPile, daysAgo: 51)
            }

            self.createTextEntry(
                context: context,
                title: "GraphQL Basics",
                content: """
                # GraphQL Query Language

                ## Basic Query
                ```graphql
                query {
                  user(id: "123") {
                    name
                    email
                    posts {
                      title
                      content
                    }
                  }
                }
                ```

                ## Mutations
                ```graphql
                mutation {
                  createPost(title: "Hello", content: "World") {
                    id
                    title
                  }
                }
                ```

                ## Fragments
                ```graphql
                fragment UserFields on User {
                  id
                  name
                  email
                }
                ```

                ## Benefits
                - Request exactly what you need
                - Single endpoint
                - Strong typing
                - No over/under fetching

                ## vs REST
                - Flexible queries
                - Fewer round trips
                - Better developer experience
                - Self-documenting
                """,
                pile: resourcesPile,
                daysAgo: 53
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.graphql.org",
                pile: resourcesPile,
                daysAgo: 54
            )

            if let imageData15 = self.createPlaceholderImage(text: "📚 API\nDocs", color: .systemOrange) {
                self.createImageEntry(context: context, image: imageData15, pile: resourcesPile, daysAgo: 53)
            }

            // Add more orphan entries to Inbox
            self.createTextEntry(
                context: context,
                title: "Quick Note",
                content: "Remember to check the documentation for the new API endpoints.",
                pile: nil,
                daysAgo: 55
            )

            self.createTextEntry(
                context: context,
                title: "Random Thought",
                content: """
                What if we could use AR to visualize data structures in 3D space?

                Students could walk around and explore algorithms as they execute.
                """,
                pile: nil,
                daysAgo: 56
            )

            self.createTextEntry(
                context: context,
                title: "Shopping List",
                content: """
                # Groceries

                - Milk
                - Eggs
                - Bread
                - Coffee beans
                - Fresh vegetables
                - Chicken breast
                """,
                pile: nil,
                daysAgo: 57
            )

            self.createTextEntry(
                context: context,
                title: "Meeting Reminder",
                content: "Team standup tomorrow at 10 AM. Don't forget to prepare the sprint report!",
                pile: nil,
                daysAgo: 58
            )

            self.createTextEntry(
                context: context,
                title: "Quote to Remember",
                content: """
                "The best time to plant a tree was 20 years ago. The second best time is now."
                - Chinese Proverb

                Start today, not tomorrow.
                """,
                pile: nil,
                daysAgo: 59
            )

            self.createTextEntry(
                context: context,
                title: "Password Reset Needed",
                content: "Need to update passwords for: Email, Banking app, Cloud storage. Use password manager!",
                pile: nil,
                daysAgo: 60
            )

            self.createTextEntry(
                context: context,
                title: "Gift Ideas",
                content: """
                # Birthday/Holiday Gifts

                - Mom: Book she mentioned
                - Dad: Tool set
                - Sister: Concert tickets
                - Best friend: Custom photo album
                """,
                pile: nil,
                daysAgo: 61
            )

            self.createTextEntry(
                context: context,
                title: "Movie Watchlist",
                content: """
                # Movies to Watch

                - The Shawshank Redemption
                - Inception
                - Interstellar
                - The Matrix
                - Parasite
                """,
                pile: nil,
                daysAgo: 62
            )

            self.createTextEntry(
                context: context,
                title: "Dentist Appointment",
                content: "Scheduled for next Tuesday at 2 PM. Location: Downtown Dental, 123 Main St.",
                pile: nil,
                daysAgo: 63
            )

            self.createTextEntry(
                context: context,
                title: "Blog Post Idea",
                content: """
                # Article: "10 Tips for Better Code Reviews"

                - Be kind and constructive
                - Look for patterns, not nitpicks
                - Ask questions instead of demanding changes
                - Praise good work
                - Focus on learning
                """,
                pile: nil,
                daysAgo: 64
            )

            // Add code snippet to Inbox
            self.createCodeEntry(
                context: context,
                title: "Quick Utility Function",
                content: """
                // Format currency with locale support
                func formatCurrency(_ amount: Double, locale: Locale = .current) -> String {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.locale = locale
                    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
                }

                // Usage
                let price = 1234.56
                print(formatCurrency(price)) // $1,234.56
                print(formatCurrency(price, locale: Locale(identifier: "en_GB"))) // £1,234.56
                """,
                language: "swift",
                pile: nil,
                daysAgo: 65
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.youtube.com",
                pile: nil,
                daysAgo: 66
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.twitter.com",
                pile: nil,
                daysAgo: 67
            )

            self.createLinkEntry(
                context: context,
                url: "https://www.wikipedia.org",
                pile: nil,
                daysAgo: 68
            )

            if let imageData16 = self.createPlaceholderImage(text: "📸 Screenshot", color: .systemGray) {
                self.createImageEntry(context: context, image: imageData16, pile: nil, daysAgo: 55)
            }

            if let imageData17 = self.createPlaceholderImage(text: "💡 Idea\nSketch", color: .systemYellow) {
                self.createImageEntry(context: context, image: imageData17, pile: nil, daysAgo: 57)
            }

            if let imageData18 = self.createPlaceholderImage(text: "📋 To-Do\nList", color: .systemPink) {
                self.createImageEntry(context: context, image: imageData18, pile: nil, daysAgo: 59)
            }

            // Final save
            do {
                try context.save()
                self.isDemoDataActive = true
                os_log("✅ Demo data created successfully - 83 entries total will sync to CloudKit", log: .cloudKitSync, type: .info)
            } catch {
                os_log("❌ Error saving demo data: %{public}@", log: .cloudKitSync, type: .error, error.localizedDescription)
            }
        }
    }

    // Remove all demo data
    func removeDemoData(context: NSManagedObjectContext) {
        guard isDemoDataActive else { return }

        os_log("🗑️ Removing demo data...", log: .cloudKitSync, type: .info)

        context.perform {
            var entriesCount = 0
            var pilesCount = 0

            // Fetch all entries and delete them individually
            let entryFetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            do {
                let entries = try context.fetch(entryFetchRequest)
                entriesCount = entries.count
                for entry in entries {
                    context.delete(entry)
                }
                os_log("🗑️ Marked %d entries for deletion", log: .cloudKitSync, type: .info, entriesCount)
            } catch {
                os_log("❌ Error fetching entries: %{public}@", log: .cloudKitSync, type: .error, error.localizedDescription)
                return
            }

            // Fetch all piles and delete them individually
            let pileFetchRequest: NSFetchRequest<Pile> = Pile.fetchRequest()
            do {
                let piles = try context.fetch(pileFetchRequest)
                pilesCount = piles.count
                for pile in piles {
                    context.delete(pile)
                }
                os_log("🗑️ Marked %d piles for deletion", log: .cloudKitSync, type: .info, pilesCount)
            } catch {
                os_log("❌ Error fetching piles: %{public}@", log: .cloudKitSync, type: .error, error.localizedDescription)
                return
            }

            // Save the deletions
            do {
                try context.save()
                os_log("✅ Demo data removed successfully - deletions will sync to CloudKit", log: .cloudKitSync, type: .info)

                // Update the flag on the main thread
                DispatchQueue.main.async {
                    self.isDemoDataActive = false
                }
            } catch {
                os_log("❌ Error saving deletions: %{public}@", log: .cloudKitSync, type: .error, error.localizedDescription)
            }
        }
    }

    // Helper functions
    private func createPile(context: NSManagedObjectContext, name: String, description: String, tag: String) -> Pile {
        let pile = Pile(context: context)
        pile.id = UUID()
        pile.name = name
        pile.desc = description
        pile.tag = tag
        return pile
    }

    private func createTextEntry(context: NSManagedObjectContext, title: String, content: String, pile: Pile?, daysAgo: Int = 0) {
        assert(!title.isEmpty, "Entry title cannot be empty")
        assert(!content.isEmpty, "Entry content cannot be empty")

        let entry = Entry(context: context)
        entry.id = UUID()
        entry.timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        entry.title = title
        entry.content = content
        entry.isMarkdown = true
        entry.language = "markdown"
        entry.type = EntryType.text.rawValue

        if let pile = pile {
            pile.addToEntries(entry)
        }
    }

    private func createCodeEntry(context: NSManagedObjectContext, title: String, content: String, language: String, pile: Pile?, daysAgo: Int = 0) {
        assert(!title.isEmpty, "Code entry title cannot be empty")
        assert(!content.isEmpty, "Code entry content cannot be empty")
        assert(!language.isEmpty, "Code entry language cannot be empty")

        let entry = Entry(context: context)
        entry.id = UUID()
        entry.timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        entry.title = title
        entry.content = content
        entry.isMarkdown = false
        entry.language = language
        entry.type = EntryType.text.rawValue

        if let pile = pile {
            pile.addToEntries(entry)
        }
    }

    private func createLinkEntry(context: NSManagedObjectContext, url: String, pile: Pile?, daysAgo: Int = 0) {
        assert(!url.isEmpty, "Link URL cannot be empty")
        assert(URL(string: url) != nil, "Link URL must be valid: \(url)")

        let entry = Entry(context: context)
        entry.id = UUID()
        entry.timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        entry.type = EntryType.link.rawValue
        entry.link = URL(string: url)

        // Extract domain name for title
        if let url = URL(string: url), let host = url.host {
            entry.title = host.replacingOccurrences(of: "www.", with: "")
        } else {
            entry.title = "Link"
        }

        assert(entry.title != nil && !entry.title!.isEmpty, "Link entry must have a title")

        if let pile = pile {
            pile.addToEntries(entry)
        }
    }

    private func createImageEntry(context: NSManagedObjectContext, image: Data, pile: Pile?, daysAgo: Int = 0) {
        assert(!image.isEmpty, "Image data cannot be empty")

        let entry = Entry(context: context)
        entry.id = UUID()
        entry.timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        entry.type = EntryType.image.rawValue
        entry.image = image
        entry.title = "Image"

        assert(entry.title != nil && !entry.title!.isEmpty, "Image entry must have a title")

        if let pile = pile {
            pile.addToEntries(entry)
        }
    }

    private func createPlaceholderImage(text: String, color: UIColor) -> Data? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Fill background with gradient
            let colors = [color.withAlphaComponent(0.6), color.withAlphaComponent(0.9)]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { $0.cgColor } as CFArray,
                locations: [0.0, 1.0]
            )

            if let gradient = gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            // Add decorative pattern
            let patternColor = UIColor.white.withAlphaComponent(0.1)
            patternColor.setStroke()
            context.cgContext.setLineWidth(2)

            // Draw diagonal lines pattern
            for i in stride(from: -size.height, to: size.width + size.height, by: 50) {
                context.cgContext.move(to: CGPoint(x: i, y: 0))
                context.cgContext.addLine(to: CGPoint(x: i + size.height, y: size.height))
                context.cgContext.strokePath()
            }

            // Draw text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .strokeWidth: -3.0,
                .strokeColor: UIColor.black.withAlphaComponent(0.3)
            ]

            let textRect = CGRect(
                x: 0,
                y: (size.height - 150) / 2,
                width: size.width,
                height: 150
            )

            text.draw(in: textRect, withAttributes: attributes)

            // Add "Demo Mode" watermark
            let watermarkStyle = NSMutableParagraphStyle()
            watermarkStyle.alignment = .center
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                .paragraphStyle: watermarkStyle
            ]

            let watermarkRect = CGRect(
                x: 0,
                y: size.height - 50,
                width: size.width,
                height: 30
            )
            "Demo Mode".draw(in: watermarkRect, withAttributes: watermarkAttributes)
        }

        return image.jpegData(compressionQuality: 0.8)
    }

}
