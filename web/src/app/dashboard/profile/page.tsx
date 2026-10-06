'use client';

import { useAuth } from '@/context/AuthContext';

export default function ProfilePage() {
    const { user } = useAuth();

    const getCreditScoreColor = (score: number) => {
        if (score >= 80) return 'text-green-600';
        if (score >= 60) return 'text-yellow-600';
        return 'text-red-600';
    };

    const getCreditScoreLabel = (score: number) => {
        if (score >= 90) return 'Excellent';
        if (score >= 80) return 'Good';
        if (score >= 60) return 'Fair';
        return 'Needs Improvement';
    };

    const getCreditBenefits = (score: number) => {
        if (score >= 90) return ['Priority booking access', '10% discount on all rentals', 'Free upgrades when available', 'No deposit required'];
        if (score >= 80) return ['5% discount on all rentals', 'Reduced deposit', 'Early access to new vehicles'];
        if (score >= 60) return ['Standard rates', 'Standard deposit'];
        return ['Higher deposit required', 'Limited vehicle selection'];
    };

    return (
        <div className="max-w-4xl mx-auto">
            <h1 className="text-3xl font-bold text-gray-900 mb-8">My Profile</h1>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {}
                <div className="bg-white rounded-xl shadow-md p-6">
                    <h2 className="text-xl font-semibold text-gray-900 mb-4">Personal Information</h2>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-500">Full Name</label>
                            <p className="text-lg text-gray-900">{user?.full_name || 'Not set'}</p>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-500">Email</label>
                            <p className="text-lg text-gray-900">{user?.email}</p>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-500">Account Type</label>
                            <p className="text-lg text-gray-900 capitalize">{user?.role}</p>
                        </div>
                    </div>
                </div>

                {}
                <div className="bg-white rounded-xl shadow-md p-6">
                    <h2 className="text-xl font-semibold text-gray-900 mb-4">Credit Score</h2>
                    <div className="text-center mb-6">
                        <div className={`text-6xl font-bold ${getCreditScoreColor(user?.credit_score || 0)}`}>
                            {user?.credit_score?.toFixed(1) || '0.0'}
                        </div>
                        <p className={`text-lg mt-2 ${getCreditScoreColor(user?.credit_score || 0)}`}>
                            {getCreditScoreLabel(user?.credit_score || 0)}
                        </p>
                    </div>

                    {}
                    <div className="w-full bg-gray-200 rounded-full h-3 mb-4">
                        <div
                            className={`h-3 rounded-full ${(user?.credit_score || 0) >= 80 ? 'bg-green-500' :
                                    (user?.credit_score || 0) >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                                }`}
                            style={{ width: `${user?.credit_score || 0}%` }}
                        ></div>
                    </div>

                    <p className="text-sm text-gray-500">
                        Your credit score affects your rental rates and available perks.
                    </p>
                </div>

                {}
                <div className="bg-white rounded-xl shadow-md p-6 md:col-span-2">
                    <h2 className="text-xl font-semibold text-gray-900 mb-4">Your Benefits</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        {getCreditBenefits(user?.credit_score || 0).map((benefit, index) => (
                            <div key={index} className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                <span className="text-gray-700">{benefit}</span>
                            </div>
                        ))}
                    </div>
                </div>

                {}
                {(user?.credit_score || 0) < 90 && (
                    <div className="bg-blue-50 rounded-xl p-6 md:col-span-2">
                        <h2 className="text-xl font-semibold text-blue-900 mb-4">Tips to Improve Your Score</h2>
                        <ul className="space-y-2 text-blue-800">
                            <li>• Return vehicles on time or early</li>
                            <li>• Keep vehicles clean and in good condition</li>
                            <li>• Complete all inspections promptly</li>
                            <li>• Avoid damages - use the AI inspection to document vehicle condition</li>
                        </ul>
                    </div>
                )}
            </div>
        </div>
    );
}
