'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';

interface Incident {
    id: number;
    booking_id: number;
    severity_grade: string;
    damage_detected: boolean;
    damage_summary: string;
    damage_cost_estimate: number;
    credit_adjustment: number;
    admin_reviewed: boolean;
    created_at: string | null;
    vehicle: { make: string; model: string; year: number } | null;
    user: { full_name: string; email: string; credit_score: number } | null;
    booking_status: string;
    has_pre_inspection: boolean;
}

interface Stats {
    total_incidents: number;
    pending_review: number;
    resolved: number;
    total_damage_cost: number;
}

const SEV: Record<string, { bg: string; text: string; border: string; dot: string; icon: string; label: string }> = {
    severe: { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200', dot: 'bg-red-500', icon: '🔴', label: 'Severe' },
    moderate: { bg: 'bg-orange-50', text: 'text-orange-700', border: 'border-orange-200', dot: 'bg-orange-500', icon: '🟠', label: 'Moderate' },
    minor: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', dot: 'bg-amber-400', icon: '🟡', label: 'Minor' },
    none: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', dot: 'bg-emerald-500', icon: '🟢', label: 'None' },
};
function sev(g: string) { return SEV[g?.toLowerCase()] || SEV.none; }

export default function IncidentsPage() {
    const { token } = useAuth();
    const router = useRouter();
    const [incidents, setIncidents] = useState<Incident[]>([]);
    const [stats, setStats] = useState<Stats | null>(null);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<'all' | 'pending' | 'resolved'>('all');

    const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        if (!token) return;
        const headers = { Authorization: `Bearer ${token}` };

        Promise.all([
            fetch(`${API}/incidents/`, { headers }).then(r => r.ok ? r.json() : []),
            fetch(`${API}/incidents/stats`, { headers }).then(r => r.ok ? r.json() : null),
        ])
            .then(([incData, statsData]) => {
                setIncidents(incData);
                setStats(statsData);
            })
            .catch(err => console.error('Fetch error:', err))
            .finally(() => setLoading(false));
    }, [token, API]);

    const filtered = incidents.filter(i => {
        if (filter === 'pending') return !i.admin_reviewed;
        if (filter === 'resolved') return i.admin_reviewed;
        return true;
    });

    const goToReview = () => {
        router.push('/admin/inspections');
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="flex flex-col items-center gap-3">
                    <div className="w-10 h-10 border-3 border-orange-500 border-t-transparent rounded-full animate-spin" />
                    <p className="text-sm text-gray-500 animate-pulse">Loading incidents...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50/50 p-4 lg:p-6">
            {}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Incident Reports</h1>
                    <p className="text-sm text-gray-500 mt-0.5">Damage incidents logged from vehicle rental inspections</p>
                </div>
                <div className="flex items-center gap-3">
                    {}
                    <div className="flex bg-white rounded-lg border shadow-sm p-0.5">
                        {(['all', 'pending', 'resolved'] as const).map(f => (
                            <button
                                key={f}
                                onClick={() => setFilter(f)}
                                className={`px-3 py-1.5 rounded-md text-xs font-semibold transition-all capitalize ${filter === f
                                        ? 'bg-slate-800 text-white shadow-sm'
                                        : 'text-gray-500 hover:text-gray-700'
                                    }`}
                            >
                                {f === 'pending' && stats ? `${f} (${stats.pending_review})` : f}
                            </button>
                        ))}
                    </div>
                </div>
            </div>

            {}
            {stats && (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    <StatCard
                        label="Total Incidents"
                        value={stats.total_incidents.toString()}
                        icon={<svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" /></svg>}
                        color="orange"
                    />
                    <StatCard
                        label="Pending Review"
                        value={stats.pending_review.toString()}
                        icon={<svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
                        color="red"
                    />
                    <StatCard
                        label="Resolved"
                        value={stats.resolved.toString()}
                        icon={<svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
                        color="green"
                    />
                    <StatCard
                        label="Total Damage Cost"
                        value={`$${stats.total_damage_cost.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
                        icon={<svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
                        color="blue"
                    />
                </div>
            )}

            {}
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="px-5 py-4 bg-gradient-to-r from-slate-800 to-slate-700 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <svg className="w-5 h-5 text-orange-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                        <h2 className="text-white font-bold text-sm">Damage Incident Logs</h2>
                    </div>
                    <span className="bg-white/20 text-white text-xs font-medium px-2 py-0.5 rounded-full">
                        {filtered.length} {filter !== 'all' ? filter : 'total'}
                    </span>
                </div>

                {filtered.length === 0 ? (
                    <div className="p-12 text-center">
                        <svg className="w-12 h-12 mx-auto text-gray-200 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                        <p className="text-gray-400 text-sm">No {filter !== 'all' ? filter : ''} incidents found</p>
                    </div>
                ) : (
                    <div className="divide-y divide-gray-100">
                        {filtered.map((inc) => {
                            const s = sev(inc.severity_grade);
                            const vehicleName = inc.vehicle
                                ? `${inc.vehicle.year} ${inc.vehicle.make} ${inc.vehicle.model}`
                                : 'Unknown Vehicle';

                            return (
                                <div key={inc.id} className="p-5 hover:bg-gray-50/50 transition-colors">
                                    <div className="flex flex-col lg:flex-row lg:items-start gap-4">
                                        {}
                                        <div className="flex-1 min-w-0">
                                            <div className="flex flex-wrap items-center gap-2 mb-2">
                                                {}
                                                <span className={`inline-flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-full border ${s.bg} ${s.text} ${s.border}`}>
                                                    <span className={`w-2 h-2 rounded-full ${s.dot}`} />
                                                    {s.label.toUpperCase()}
                                                </span>
                                                {}
                                                {inc.admin_reviewed ? (
                                                    <span className="inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                        ✓ Reviewed
                                                    </span>
                                                ) : (
                                                    <span className="inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-orange-50 text-orange-700 border border-orange-200 animate-pulse">
                                                        ⏳ Pending
                                                    </span>
                                                )}
                                                {}
                                                {inc.damage_detected && (
                                                    <span className="inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-red-50 text-red-600 border border-red-200">
                                                        ⚠ Damage Detected
                                                    </span>
                                                )}
                                            </div>

                                            {}
                                            <p className="text-sm text-gray-800 font-medium mb-2 leading-relaxed">{inc.damage_summary}</p>

                                            {}
                                            <div className="flex flex-wrap items-center gap-x-5 gap-y-1 text-xs text-gray-400">
                                                <span className="inline-flex items-center gap-1">
                                                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
                                                    {vehicleName}
                                                </span>
                                                <span className="inline-flex items-center gap-1">
                                                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                                                    {inc.user?.full_name || inc.user?.email || 'Unknown'}
                                                </span>
                                                <span className="inline-flex items-center gap-1">
                                                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                                                    {inc.created_at ? new Date(inc.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'N/A'}
                                                </span>
                                                <span className="text-gray-300">|</span>
                                                <span>Booking #{inc.booking_id}</span>
                                            </div>
                                        </div>

                                        {}
                                        <div className="flex lg:flex-col items-center lg:items-end gap-3 shrink-0">
                                            {}
                                            <div className="text-right">
                                                <p className="text-xs text-gray-400 mb-0.5">Damage Cost</p>
                                                <p className={`text-xl font-black ${inc.damage_cost_estimate > 0 ? 'text-red-600' : 'text-gray-400'}`}>
                                                    ${inc.damage_cost_estimate.toFixed(2)}
                                                </p>
                                            </div>
                                            {}
                                            {inc.credit_adjustment !== 0 && (
                                                <div className="text-right">
                                                    <p className="text-xs text-gray-400 mb-0.5">Credit</p>
                                                    <p className={`text-sm font-bold ${inc.credit_adjustment < 0 ? 'text-red-500' : 'text-emerald-500'}`}>
                                                        {inc.credit_adjustment > 0 ? '+' : ''}{inc.credit_adjustment}
                                                    </p>
                                                </div>
                                            )}
                                            {}
                                            {!inc.admin_reviewed ? (
                                                <button
                                                    onClick={goToReview}
                                                    className="inline-flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white text-xs font-semibold rounded-lg shadow-sm transition-all hover:shadow-md active:scale-[0.98]"
                                                >
                                                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                                    Review & Resolve
                                                </button>
                                            ) : (
                                                <span className="inline-flex items-center gap-1 text-xs text-emerald-600 font-semibold bg-emerald-50 px-3 py-1.5 rounded-lg border border-emerald-200">
                                                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                                                    Resolved
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        </div>
    );
}

function StatCard({ label, value, icon, color }: { label: string; value: string; icon: React.ReactNode; color: string }) {
    const colors: Record<string, string> = {
        orange: 'bg-orange-50 text-orange-600 border-orange-200',
        red: 'bg-red-50 text-red-600 border-red-200',
        green: 'bg-emerald-50 text-emerald-600 border-emerald-200',
        blue: 'bg-blue-50 text-blue-600 border-blue-200',
    };
    const iconColors: Record<string, string> = {
        orange: 'bg-orange-100 text-orange-600',
        red: 'bg-red-100 text-red-600',
        green: 'bg-emerald-100 text-emerald-600',
        blue: 'bg-blue-100 text-blue-600',
    };

    return (
        <div className={`bg-white rounded-xl border shadow-sm p-4 hover:shadow-md transition-shadow`}>
            <div className="flex items-center justify-between">
                <div>
                    <p className="text-xs font-medium text-gray-400 uppercase tracking-wider mb-1">{label}</p>
                    <p className="text-2xl font-black text-gray-900">{value}</p>
                </div>
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${iconColors[color]}`}>
                    {icon}
                </div>
            </div>
        </div>
    );
}
