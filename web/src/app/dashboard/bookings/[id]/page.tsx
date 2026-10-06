'use client';

import { useAuth } from '@/context/AuthContext';
import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { ArrowLeft, Car, Calendar, DollarSign, AlertCircle, CheckCircle, Clock } from 'lucide-react';
import Link from 'next/link';

interface BookingDetail {
    id: number;
    start_date: string;
    end_date: string;
    actual_end_date?: string;
    total_price: number;
    paid_amount: number;
    refund_amount: number;
    status: string;
    vehicle?: {
        make: string;
        model: string;
        year: number;
        image_url: string;
        daily_rate: number;
    };
    post_inspection?: {
        severity_grade: string;
        damage_summary: string;
        credit_adjustment: number;
        damage_cost_estimate: number;
        admin_reviewed: boolean;
        ai_analysis_json?: string;
    };
}

export default function BookingDetailsPage() {
    const { token } = useAuth();
    const router = useRouter();
    const params = useParams();
    const [booking, setBooking] = useState<BookingDetail | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState('');

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        const fetchBooking = async () => {
            if (!token || !params.id) return;
            try {
                const response = await fetch(`${API_URL}/bookings/${params.id}`, {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                    },
                });

                if (response.ok) {
                    const data = await response.json();

                    let postInspection = null;
                    if (data.status === 'completed' || data.post_inspection_complete) {
                        try {
                            const inspRes = await fetch(`${API_URL}/rental/results/${params.id}`, {
                                headers: { 'Authorization': `Bearer ${token}` }
                            });
                            if (inspRes.ok) {
                                postInspection = await inspRes.json();
                            }
                        } catch (e) {
                            console.error("No inspection found or error", e);
                        }
                    }

                    setBooking({ ...data, post_inspection: postInspection });
                } else {
                    setError('Booking not found');
                }
            } catch (error) {
                console.error('Error fetching booking:', error);
                setError('Failed to load booking details');
            } finally {
                setIsLoading(false);
            }
        };

        fetchBooking();
    }, [token, params.id, API_URL]);

    if (isLoading) {
        return (
            <div className="flex justify-center items-center min-h-[50vh]">
                <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
            </div>
        );
    }

    if (error || !booking) {
        return (
            <div className="text-center py-12">
                <p className="text-red-500 mb-4">{error || 'Booking not found'}</p>
                <Link href="/dashboard/bookings" className="text-blue-600 hover:underline flex items-center justify-center gap-2">
                    <ArrowLeft className="w-4 h-4" /> Back to My Bookings
                </Link>
            </div>
        );
    }

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'completed': return 'bg-green-100 text-green-800 border-green-200';
            case 'active': return 'bg-blue-100 text-blue-800 border-blue-200';
            case 'pending': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
            case 'cancelled': return 'bg-red-100 text-red-800 border-red-200';
            default: return 'bg-gray-100 text-gray-800 border-gray-200';
        }
    };

    const vehicle = booking.vehicle;
    const rawImageUrl = vehicle?.image_url;
    const imageUrl = rawImageUrl
        ? (rawImageUrl.startsWith('http') ? rawImageUrl : `${API_URL}${rawImageUrl}`)
        : null;

    let adminNotes = null;
    if (booking.post_inspection?.ai_analysis_json) {
        try {
            const analysis = JSON.parse(booking.post_inspection.ai_analysis_json);
            if (analysis.admin_notes) {
                adminNotes = analysis.admin_notes;
            }
        } catch (e) { }
    }

    return (
        <div className="max-w-4xl mx-auto">
            <Link
                href="/dashboard/bookings"
                className="inline-flex items-center text-gray-500 hover:text-gray-900 mb-6 transition-colors"
            >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to all bookings
            </Link>

            {}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden mb-6">
                <div className="p-6 md:p-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <div className="flex items-center gap-3 mb-2">
                            <h1 className="text-2xl font-bold text-gray-900">Booking #{booking.id}</h1>
                            <span className={`px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(booking.status)}`}>
                                {booking.status.charAt(0).toUpperCase() + booking.status.slice(1)}
                            </span>
                        </div>
                        <p className="text-gray-500 flex items-center gap-2">
                            <Calendar className="w-4 h-4" />
                            {new Date(booking.start_date).toLocaleDateString()} - {new Date(booking.end_date).toLocaleDateString()}
                        </p>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {}
                <div className="md:col-span-2 space-y-6">
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                            <Car className="w-5 h-5 text-blue-600" />
                            Vehicle Details
                        </h2>
                        <div className="flex flex-col sm:flex-row gap-6">
                            <div className="w-full sm:w-48 h-32 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
                                {imageUrl ? (
                                    <img src={imageUrl} alt={vehicle?.model || 'Vehicle'} className="w-full h-full object-cover" />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-gray-400">
                                        <Car className="w-8 h-8 opacity-50" />
                                    </div>
                                )}
                            </div>
                            <div>
                                <h3 className="text-xl font-bold text-gray-900">
                                    {vehicle ? `${vehicle.make} ${vehicle.model}` : 'Unknown Vehicle'}
                                </h3>
                                <p className="text-gray-500 mb-2">{vehicle?.year || 'N/A'}</p>
                                <p className="text-sm text-gray-600">Daily Rate: ${vehicle?.daily_rate || 0}/day</p>
                            </div>
                        </div>
                    </div>

                    {}
                    {(booking.post_inspection) && (
                        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                            <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                                <AlertCircle className="w-5 h-5 text-purple-600" />
                                Inspection Report
                            </h2>

                            <div className="space-y-4">
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                    <div className="p-4 bg-gray-50 rounded-lg">
                                        <p className="text-sm text-gray-500 mb-1">Severity Grade</p>
                                        <p className={`font-semibold capitalize ${booking.post_inspection.severity_grade === 'none' ? 'text-green-600' :
                                            booking.post_inspection.severity_grade === 'severe' ? 'text-red-600' : 'text-yellow-600'
                                            }`}>
                                            {booking.post_inspection.severity_grade || 'None'}
                                        </p>
                                    </div>
                                    <div className="p-4 bg-gray-50 rounded-lg">
                                        <p className="text-sm text-gray-500 mb-1">Credit Adjustment</p>
                                        <p className={`font-semibold ${booking.post_inspection.credit_adjustment >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                                            {booking.post_inspection.credit_adjustment > 0 ? '+' : ''}
                                            {booking.post_inspection.credit_adjustment} Points
                                        </p>
                                    </div>
                                </div>

                                {booking.post_inspection.damage_summary && (
                                    <div className="p-4 bg-red-50 border border-red-100 rounded-lg">
                                        <h4 className="font-semibold text-red-900 mb-2">Damage Summary</h4>
                                        <p className="text-sm text-red-800">{booking.post_inspection.damage_summary}</p>
                                        {booking.post_inspection.damage_cost_estimate > 0 && (
                                            <p className="text-sm font-semibold text-red-900 mt-2">
                                                Estimated Cost: ${booking.post_inspection.damage_cost_estimate}
                                            </p>
                                        )}
                                    </div>
                                )}

                                {adminNotes && (
                                    <div className="p-4 bg-blue-50 border border-blue-100 rounded-lg">
                                        <h4 className="font-semibold text-blue-900 mb-2">Admin Comments</h4>
                                        <p className="text-sm text-blue-800">{adminNotes}</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    )}
                </div>

                {}
                <div className="md:col-span-1">
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 sticky top-6">
                        <h2 className="text-lg font-semibold text-gray-900 mb-6 flex items-center gap-2">
                            <DollarSign className="w-5 h-5 text-green-600" />
                            Payment Details
                        </h2>

                        <div className="space-y-4 text-sm">
                            <div className="flex justify-between">
                                <span className="text-gray-600">Total Rental Cost</span>
                                <span className="font-medium">${(booking.total_price || 0).toFixed(2)}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-gray-600">Amount Paid</span>
                                <span className="font-medium">${(booking.paid_amount || 0).toFixed(2)}</span>
                            </div>

                            {(booking.refund_amount || 0) > 0 && (
                                <div className="flex justify-between text-green-600">
                                    <span>Refund (Early Return)</span>
                                    <span className="font-bold">-${(booking.refund_amount || 0).toFixed(2)}</span>
                                </div>
                            )}

                            {booking.post_inspection && (booking.post_inspection.damage_cost_estimate || 0) > 0 && (
                                <div className="flex justify-between text-red-600">
                                    <span>Damage Cost</span>
                                    <span className="font-bold">+${(booking.post_inspection.damage_cost_estimate || 0).toFixed(2)}</span>
                                </div>
                            )}

                            <div className="border-t pt-4 mt-4">
                                <div className="flex justify-between text-lg font-bold text-gray-900">
                                    <span>Net Total</span>
                                    <span>
                                        ${((booking.paid_amount || 0) - (booking.refund_amount || 0) + (booking.post_inspection?.damage_cost_estimate || 0)).toFixed(2)}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
