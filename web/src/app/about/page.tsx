import { Navbar } from "@/components/Navbar";
import { Shield, Users, Zap, Award } from "lucide-react";

export default function AboutPage() {
    return (
        <div className="min-h-screen flex flex-col">
            <Navbar />

            {}
            <section className="py-20 px-4 bg-gradient-to-r from-blue-600 to-blue-800 text-white">
                <div className="max-w-4xl mx-auto text-center">
                    <h1 className="text-4xl md:text-5xl font-bold mb-6">About AutoVision Rent</h1>
                    <p className="text-xl text-blue-100">
                        Revolutionizing vehicle rentals with AI-powered transparency and trust.
                    </p>
                </div>
            </section>

            {}
            <section className="py-16 px-4">
                <div className="max-w-4xl mx-auto">
                    <h2 className="text-3xl font-bold text-center mb-8">Our Mission</h2>
                    <p className="text-lg text-gray-600 text-center leading-relaxed">
                        At AutoVision Rent, we believe in creating a fair and transparent rental experience
                        for everyone. Our AI-powered damage detection system eliminates disputes, while our
                        dynamic credit system rewards responsible renters with better rates and premium access.
                    </p>
                </div>
            </section>

            {}
            <section className="py-16 px-4 bg-gray-50">
                <div className="max-w-6xl mx-auto">
                    <h2 className="text-3xl font-bold text-center mb-12">Our Values</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                        <div className="bg-white p-6 rounded-xl shadow-md text-center">
                            <div className="w-14 h-14 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <Zap className="w-7 h-7 text-blue-600" />
                            </div>
                            <h3 className="font-bold text-lg mb-2">Innovation</h3>
                            <p className="text-gray-600 text-sm">
                                Using cutting-edge AI to transform the rental experience.
                            </p>
                        </div>
                        <div className="bg-white p-6 rounded-xl shadow-md text-center">
                            <div className="w-14 h-14 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <Shield className="w-7 h-7 text-green-600" />
                            </div>
                            <h3 className="font-bold text-lg mb-2">Trust</h3>
                            <p className="text-gray-600 text-sm">
                                Building confidence through transparent inspections.
                            </p>
                        </div>
                        <div className="bg-white p-6 rounded-xl shadow-md text-center">
                            <div className="w-14 h-14 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <Award className="w-7 h-7 text-purple-600" />
                            </div>
                            <h3 className="font-bold text-lg mb-2">Fairness</h3>
                            <p className="text-gray-600 text-sm">
                                Rewarding good behavior with better rates and perks.
                            </p>
                        </div>
                        <div className="bg-white p-6 rounded-xl shadow-md text-center">
                            <div className="w-14 h-14 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <Users className="w-7 h-7 text-orange-600" />
                            </div>
                            <h3 className="font-bold text-lg mb-2">Community</h3>
                            <p className="text-gray-600 text-sm">
                                Creating a safe space for renters and vehicle owners.
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            {}
            <section className="py-16 px-4">
                <div className="max-w-4xl mx-auto">
                    <h2 className="text-3xl font-bold text-center mb-12">How It Works</h2>
                    <div className="space-y-8">
                        <div className="flex items-start gap-4">
                            <div className="w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center flex-shrink-0 font-bold">
                                1
                            </div>
                            <div>
                                <h3 className="font-bold text-lg">Sign Up & Verify</h3>
                                <p className="text-gray-600">Create your account and complete verification to start renting with a 100-point credit score.</p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4">
                            <div className="w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center flex-shrink-0 font-bold">
                                2
                            </div>
                            <div>
                                <h3 className="font-bold text-lg">Book Your Vehicle</h3>
                                <p className="text-gray-600">Browse our fleet, select dates, and confirm your booking with instant availability checks.</p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4">
                            <div className="w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center flex-shrink-0 font-bold">
                                3
                            </div>
                            <div>
                                <h3 className="font-bold text-lg">AI Inspection</h3>
                                <p className="text-gray-600">Take photos at pickup and dropoff. Our AI analyzes for damage, protecting both parties.</p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4">
                            <div className="w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center flex-shrink-0 font-bold">
                                4
                            </div>
                            <div>
                                <h3 className="font-bold text-lg">Build Your Credit</h3>
                                <p className="text-gray-600">Return vehicles in good condition to boost your credit score and unlock better rates!</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {}
            <footer className="bg-gray-900 text-white py-8 px-4 mt-auto">
                <div className="max-w-6xl mx-auto text-center">
                    <p className="text-gray-400">© 2024 AutoVision Rent. All rights reserved.</p>
                </div>
            </footer>
        </div>
    );
}
