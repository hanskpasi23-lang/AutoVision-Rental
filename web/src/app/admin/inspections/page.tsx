'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';

interface InspectionDetail {
    id: number;
    type: string;
    front_image_url: string | null;
    back_image_url: string | null;
    left_image_url: string | null;
    right_image_url: string | null;
    image_url: string | null;
    damage_detected: boolean;
    damage_summary: string | null;
    damage_cost_estimate: number;
    severity_grade: string | null;
    credit_adjustment: number;
    admin_reviewed: boolean;
    created_at: string | null;
    ai_analysis: Record<string, unknown> | null;
}

interface BookingGroup {
    booking_id: number;
    booking: {
        id: number;
        status: string;
        start_date: string | null;
        end_date: string | null;
        total_price: number;
        refund_amount: number;
    } | null;
    vehicle: {
        id: number;
        make: string;
        model: string;
        year: number;
        image_url: string | null;
    } | null;
    user: {
        id: number;
        email: string;
        full_name: string;
        credit_score: number;
    } | null;
    pre_inspection: InspectionDetail | null;
    post_inspection: InspectionDetail | null;
}

const SEVERITY_CONFIG: Record<string, { bg: string; text: string; border: string; dot: string; label: string }> = {
    none: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', dot: 'bg-emerald-500', label: 'No Damage' },
    minor: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', dot: 'bg-amber-500', label: 'Minor' },
    moderate: { bg: 'bg-orange-50', text: 'text-orange-700', border: 'border-orange-200', dot: 'bg-orange-500', label: 'Moderate' },
    severe: { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200', dot: 'bg-red-500', label: 'Severe' },
};

function getSeverityStyle(grade: string | null) {
    return SEVERITY_CONFIG[grade?.toLowerCase() || ''] || SEVERITY_CONFIG.none;
}

export default function InspectionsPage() {
    const router = useRouter();
    const { token, isLoading: authLoading } = useAuth();
    const [groups, setGroups] = useState<BookingGroup[]>([]);
    const [loading, setLoading] = useState(true);
    const [selected, setSelected] = useState<BookingGroup | null>(null);
    const [overrideGrade, setOverrideGrade] = useState('');
    const [adminNotes, setAdminNotes] = useState('');
    const [saving, setSaving] = useState(false);
    const [toast, setToast] = useState<string | null>(null);

    const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        if (authLoading) return;

        if (!token) {
            setLoading(false);
            router.push('/login');
            return;
        }

        (async () => {
            try {
                const res = await fetch(`${API}/inspections/detailed`, {
                    headers: { Authorization: `Bearer ${token}` },
                });
                if (res.ok) {
                    const data: BookingGroup[] = await res.json();
                    setGroups(data);
                    if (data.length > 0) {
                        setSelected(data[0]);
                        setOverrideGrade(data[0].post_inspection?.severity_grade || 'none');
                    }
                } else {
                    console.error('API Error:', res.status, await res.text());
                }
            } catch (err) {
                console.error('Fetch error:', err);
            } finally {
                setLoading(false);
            }
        })();
    }, [token, API, authLoading, router]);

    const selectGroup = (g: BookingGroup) => {
        setSelected(g);
        setOverrideGrade(g.post_inspection?.severity_grade || 'none');
        setAdminNotes('');
    };

    const submitReview = async (action: 'accept_ai' | 'override') => {
        if (!selected?.post_inspection) return;
        setSaving(true);
        try {
            const body: Record<string, unknown> = { action };
            if (action === 'override') {
                body.severity_grade = overrideGrade;
            }
            if (adminNotes.trim()) {
                body.admin_notes = adminNotes;
            }

            const res = await fetch(`${API}/inspections/${selected.post_inspection.id}/review-complete`, {
                method: 'PUT',
                headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
                body: JSON.stringify(body),
            });

            if (res.ok) {
                const result = await res.json();

                const finalSeverity = action === 'override' ? overrideGrade : selected.post_inspection.severity_grade;
                const updated = groups.map(g => {
                    if (g.booking_id === selected.booking_id && g.post_inspection) {
                        return {
                            ...g,
                            booking: g.booking ? { ...g.booking, status: 'completed' } : g.booking,
                            post_inspection: { ...g.post_inspection, severity_grade: finalSeverity, admin_reviewed: true },
                        };
                    }
                    return g;
                });
                setGroups(updated);
                const updatedSelected = updated.find(g => g.booking_id === selected.booking_id) || null;
                setSelected(updatedSelected);

                const creditStr = result.credit_adjustment > 0 ? `+${result.credit_adjustment}` : `${result.credit_adjustment}`;
                let toastMsg = `✅ Review submitted! Credit: ${creditStr} pts.`;
                if (result.refund_processed > 0) {
                    toastMsg += ` Refund: $${result.refund_processed.toFixed(2)}.`;
                }
                toastMsg += ' Notification sent to user.';
                showToast(toastMsg);
            } else {
                const errData = await res.json().catch(() => ({}));
                showToast(`❌ Error: ${errData.detail || 'Failed to submit review'}`);
            }
        } catch (err) {
            console.error('Review error:', err);
            showToast('❌ Network error. Please try again.');
        } finally {
            setSaving(false);
        }
    };

    const showToast = (msg: string) => {
        setToast(msg);
        setTimeout(() => setToast(null), 3000);
    };

    const ImagePanel = ({ inspection, label, accent }: { inspection: InspectionDetail | null; label: string; accent: string }) => {
        const angles = inspection ? [
            { name: 'Front', url: inspection.front_image_url },
            { name: 'Back', url: inspection.back_image_url },
            { name: 'Left', url: inspection.left_image_url },
            { name: 'Right', url: inspection.right_image_url },
        ].filter(a => a.url) : [];

        if (angles.length === 0 && inspection?.image_url) {
            angles.push({ name: 'Photo', url: inspection.image_url });
        }

        return (
            <div className="flex-1 min-w-0">
                <div className={`flex items-center gap-2 mb-3 pb-2 border-b-2 ${accent}`}>
                    <div className={`w-2 h-2 rounded-full ${accent.replace('border-', 'bg-')}`}></div>
                    <h3 className="font-semibold text-gray-800 text-sm uppercase tracking-wide">{label}</h3>
                    {inspection && (
                        <span className="ml-auto text-xs text-gray-400">
                            {inspection.created_at ? new Date(inspection.created_at).toLocaleDateString() : ''}
                        </span>
                    )}
                </div>
                {!inspection ? (
                    <div className="flex items-center justify-center h-48 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
                        <div className="text-center text-gray-400">
                            <svg className="w-8 h-8 mx-auto mb-1 opacity-40" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                            <p className="text-xs">Not yet submitted</p>
                        </div>
                    </div>
                ) : angles.length > 0 ? (
                    <div className="grid grid-cols-2 gap-1.5">
                        {angles.map((a, i) => (
                            <div key={i} className="relative aspect-[4/3] bg-gray-100 rounded-lg overflow-hidden group cursor-pointer">
                                <img
                                    src={`${API}${a.url}`}
                                    alt={`${label} ${a.name}`}
                                    className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-110"
                                    onError={(e) => { (e.target as HTMLImageElement).src = '/placeholder.png'; }}
                                />
                                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                                <span className="absolute bottom-1 left-1.5 text-[10px] font-semibold text-white bg-black/40 px-1.5 py-0.5 rounded backdrop-blur-sm">
                                    {a.name}
                                </span>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="flex items-center justify-center h-48 bg-gray-50 rounded-lg border border-gray-200">
                        <p className="text-xs text-gray-400">No images available</p>
                    </div>
                )}
            </div>
        );
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="flex flex-col items-center gap-3">
                    <div className="w-10 h-10 border-3 border-blue-500 border-t-transparent rounded-full animate-spin" />
                    <p className="text-sm text-gray-500 animate-pulse">Loading inspections...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50/50 p-4 lg:p-6">
            {}
            {toast && (
                <div className="fixed top-4 right-4 z-50 bg-gray-900 text-white px-4 py-2.5 rounded-lg shadow-xl text-sm font-medium animate-bounce">
                    {toast}
                </div>
            )}

            {}
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-gray-900">Damage Inspection Review</h1>
                <p className="text-sm text-gray-500 mt-0.5">Compare vehicle conditions and manage AI severity assessments</p>
            </div>

            <div className="flex gap-6 items-start">
                {}
                <div className="w-72 shrink-0">
                    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden sticky top-4">
                        <div className="px-4 py-3 bg-gradient-to-r from-slate-800 to-slate-700">
                            <div className="flex items-center justify-between">
                                <h2 className="text-white font-semibold text-sm">Rental Cases</h2>
                                <span className="bg-white/20 text-white text-xs font-medium px-2 py-0.5 rounded-full">
                                    {groups.length}
                                </span>
                            </div>
                        </div>
                        <div className="max-h-[calc(100vh-180px)] overflow-y-auto divide-y divide-gray-100">
                            {groups.length === 0 ? (
                                <div className="p-8 text-center">
                                    <svg className="w-10 h-10 mx-auto text-gray-300 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                                    <p className="text-sm text-gray-400">No inspections found</p>
                                </div>
                            ) : (
                                groups.map((g) => {
                                    const sev = getSeverityStyle(g.post_inspection?.severity_grade ?? null);
                                    const needsReview = g.post_inspection && !g.post_inspection.admin_reviewed;
                                    const isActive = selected?.booking_id === g.booking_id;

                                    return (
                                        <div
                                            key={g.booking_id}
                                            onClick={() => selectGroup(g)}
                                            className={`p-3 cursor-pointer transition-all duration-150 ${isActive ? 'bg-blue-50 border-l-3 border-l-blue-500' : 'hover:bg-gray-50 border-l-3 border-l-transparent'}`}
                                        >
                                            <div className="flex items-start justify-between">
                                                <div className="min-w-0">
                                                    <p className="text-sm font-semibold text-gray-900 truncate">
                                                        {g.vehicle ? `${g.vehicle.make} ${g.vehicle.model}` : `Booking #${g.booking_id}`}
                                                    </p>
                                                    <p className="text-xs text-gray-400 truncate mt-0.5">
                                                        {g.user?.full_name || g.user?.email || 'Unknown user'}
                                                    </p>
                                                </div>
                                                {needsReview && (
                                                    <span className="shrink-0 ml-2 w-2 h-2 bg-red-500 rounded-full mt-1 animate-pulse" />
                                                )}
                                            </div>
                                            <div className="flex items-center gap-2 mt-2">
                                                <span className={`inline-flex items-center gap-1 text-[10px] font-semibold px-1.5 py-0.5 rounded border ${sev.bg} ${sev.text} ${sev.border}`}>
                                                    <span className={`w-1.5 h-1.5 rounded-full ${sev.dot}`} />
                                                    {sev.label}
                                                </span>
                                                {g.post_inspection?.admin_reviewed && (
                                                    <span className="text-[10px] text-emerald-600 font-medium">✓ Reviewed</span>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>
                </div>

                {}
                <div className="flex-1 min-w-0 space-y-5">
                    {selected ? (
                        <>
                            {}
                            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
                                <div className="flex flex-wrap items-center gap-4">
                                    {}
                                    <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow">
                                            {selected.vehicle?.make?.[0] || '?'}
                                        </div>
                                        <div>
                                            <p className="font-bold text-gray-900">
                                                {selected.vehicle ? `${selected.vehicle.year} ${selected.vehicle.make} ${selected.vehicle.model}` : `Booking #${selected.booking_id}`}
                                            </p>
                                            <p className="text-xs text-gray-400">Booking #{selected.booking_id}</p>
                                        </div>
                                    </div>
                                    <div className="h-8 w-px bg-gray-200 hidden sm:block" />
                                    {}
                                    <div className="flex items-center gap-2">
                                        <div className="w-7 h-7 rounded-full bg-gray-200 flex items-center justify-center text-xs font-semibold text-gray-600">
                                            {selected.user?.full_name?.[0] || '?'}
                                        </div>
                                        <div>
                                            <p className="text-sm font-medium text-gray-800">{selected.user?.full_name || 'N/A'}</p>
                                            <p className="text-[10px] text-gray-400">{selected.user?.email || ''}</p>
                                        </div>
                                    </div>
                                    <div className="ml-auto flex items-center gap-3 text-xs">
                                        <div className="text-center px-3 py-1.5 bg-gray-50 rounded-lg border">
                                            <p className="text-gray-400 mb-0.5">Credit Score</p>
                                            <p className="font-bold text-gray-800">{selected.user?.credit_score ?? 'N/A'}</p>
                                        </div>
                                        <div className="text-center px-3 py-1.5 bg-gray-50 rounded-lg border">
                                            <p className="text-gray-400 mb-0.5">Status</p>
                                            <p className="font-bold text-gray-800 capitalize">{selected.booking?.status || 'N/A'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {}
                            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-5">
                                <h2 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                                    <svg className="w-5 h-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" /></svg>
                                    Vehicle Condition Comparison
                                </h2>
                                <div className="flex gap-6">
                                    <ImagePanel
                                        inspection={selected.pre_inspection}
                                        label="Before Rental (Pre-Inspection)"
                                        accent="border-blue-400"
                                    />
                                    {}
                                    <div className="hidden md:flex flex-col items-center justify-center">
                                        <div className="w-px h-full bg-gradient-to-b from-transparent via-gray-300 to-transparent" />
                                        <div className="my-2 w-8 h-8 rounded-full bg-gray-100 border flex items-center justify-center">
                                            <span className="text-gray-400 text-xs font-bold">VS</span>
                                        </div>
                                        <div className="w-px h-full bg-gradient-to-b from-transparent via-gray-300 to-transparent" />
                                    </div>
                                    <ImagePanel
                                        inspection={selected.post_inspection}
                                        label="After Rental (Post-Inspection)"
                                        accent="border-orange-400"
                                    />
                                </div>
                            </div>

                            {}
                            {selected.post_inspection && (
                                <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                                    <div className="px-5 py-4 bg-gradient-to-r from-slate-800 to-slate-700 flex items-center justify-between">
                                        <div className="flex items-center gap-2">
                                            <svg className="w-5 h-5 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                                            <h2 className="text-white font-bold">AI Severity Grading Report</h2>
                                        </div>
                                        {selected.post_inspection.admin_reviewed && (
                                            <span className="bg-emerald-500/20 text-emerald-300 text-xs font-semibold px-2 py-0.5 rounded-full">
                                                ✓ Admin Reviewed
                                            </span>
                                        )}
                                    </div>

                                    <div className="p-5">
                                        {}
                                        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                                            {}
                                            {(() => {
                                                const sev = getSeverityStyle(selected.post_inspection.severity_grade);
                                                return (
                                                    <div className={`p-4 rounded-xl border-2 ${sev.border} ${sev.bg} text-center`}>
                                                        <p className="text-[10px] uppercase tracking-widest text-gray-500 mb-1">AI Grade</p>
                                                        <div className="flex items-center justify-center gap-2">
                                                            <span className={`w-3 h-3 rounded-full ${sev.dot}`} />
                                                            <span className={`text-xl font-black ${sev.text}`}>{sev.label}</span>
                                                        </div>
                                                    </div>
                                                );
                                            })()}
                                            {}
                                            <div className={`p-4 rounded-xl border text-center ${selected.post_inspection.damage_detected ? 'bg-red-50 border-red-200' : 'bg-emerald-50 border-emerald-200'}`}>
                                                <p className="text-[10px] uppercase tracking-widest text-gray-500 mb-1">Damage</p>
                                                <p className={`text-xl font-black ${selected.post_inspection.damage_detected ? 'text-red-600' : 'text-emerald-600'}`}>
                                                    {selected.post_inspection.damage_detected ? 'Detected' : 'None'}
                                                </p>
                                            </div>
                                            {}
                                            <div className="p-4 rounded-xl border bg-gray-50 text-center">
                                                <p className="text-[10px] uppercase tracking-widest text-gray-500 mb-1">Est. Cost</p>
                                                <p className="text-xl font-black text-gray-900">
                                                    ${selected.post_inspection.damage_cost_estimate?.toFixed(2) || '0.00'}
                                                </p>
                                            </div>
                                            {}
                                            <div className={`p-4 rounded-xl border text-center ${selected.post_inspection.credit_adjustment < 0 ? 'bg-red-50 border-red-200' : 'bg-emerald-50 border-emerald-200'}`}>
                                                <p className="text-[10px] uppercase tracking-widest text-gray-500 mb-1">Credit Impact</p>
                                                <p className={`text-xl font-black ${selected.post_inspection.credit_adjustment < 0 ? 'text-red-600' : 'text-emerald-600'}`}>
                                                    {selected.post_inspection.credit_adjustment > 0 ? '+' : ''}{selected.post_inspection.credit_adjustment}
                                                </p>
                                            </div>
                                        </div>

                                        {}
                                        {selected.post_inspection.damage_summary && (
                                            <div className="mb-6 bg-slate-50 rounded-lg p-4 border border-slate-200">
                                                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">AI Analysis Summary</h3>
                                                <p className="text-sm text-slate-700 leading-relaxed">{selected.post_inspection.damage_summary}</p>
                                            </div>
                                        )}

                                        {}
                                        <div className="border-t border-gray-200 pt-5">
                                            <div className="flex items-center gap-2 mb-4">
                                                <svg className="w-5 h-5 text-orange-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                                                <h3 className="font-bold text-gray-900">Admin Manual Override</h3>
                                                <span className="text-xs text-gray-400 ml-1">(Override the AI assessment if needed)</span>
                                            </div>

                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                {}
                                                <div>
                                                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Override Severity Grade</label>
                                                    <select
                                                        value={overrideGrade}
                                                        onChange={(e) => setOverrideGrade(e.target.value)}
                                                        className="w-full px-3 py-2.5 bg-white border-2 border-gray-200 rounded-lg text-sm font-semibold focus:border-blue-400 focus:ring-2 focus:ring-blue-100 outline-none transition-all cursor-pointer"
                                                    >
                                                        <option value="none">✅ None — No damage found</option>
                                                        <option value="minor">⚠️ Minor — Small scratches / scuffs</option>
                                                        <option value="moderate">🟠 Moderate — Noticeable damage</option>
                                                        <option value="severe">🔴 Severe — Major damage / structural</option>
                                                    </select>
                                                </div>
                                                {}
                                                <div>
                                                    <label className="block text-xs font-semibold text-gray-600 mb-1.5">Admin Notes (optional)</label>
                                                    <textarea
                                                        value={adminNotes}
                                                        onChange={(e) => setAdminNotes(e.target.value)}
                                                        placeholder="Reason for override..."
                                                        rows={2}
                                                        className="w-full px-3 py-2 bg-white border-2 border-gray-200 rounded-lg text-sm focus:border-blue-400 focus:ring-2 focus:ring-blue-100 outline-none transition-all resize-none"
                                                    />
                                                </div>
                                            </div>

                                            <div className="flex items-center justify-between mt-4 pt-3 border-t border-gray-100">
                                                <p className="text-xs text-gray-400">
                                                    {selected.post_inspection.admin_reviewed
                                                        ? '⚡ This case has been reviewed. You can re-submit if needed.'
                                                        : '⏳ Pending admin review — accept AI or override below.'}
                                                </p>
                                                <div className="flex items-center gap-2">
                                                    {!selected.post_inspection.admin_reviewed && (
                                                        <button
                                                            onClick={() => submitReview('accept_ai')}
                                                            disabled={saving}
                                                            className={`px-4 py-2.5 rounded-lg font-semibold text-sm shadow-sm transition-all ${saving
                                                                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                                                                : 'bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white hover:shadow-md active:scale-[0.98]'
                                                                }`}
                                                        >
                                                            {saving ? 'Processing...' : '✓ Accept AI Assessment'}
                                                        </button>
                                                    )}
                                                    <button
                                                        onClick={() => submitReview('override')}
                                                        disabled={saving}
                                                        className={`px-4 py-2.5 rounded-lg font-semibold text-sm shadow-sm transition-all ${saving
                                                            ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                                                            : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white hover:shadow-md active:scale-[0.98]'
                                                            }`}
                                                    >
                                                        {saving ? 'Processing...' : selected.post_inspection.admin_reviewed ? '⟲ Re-submit Override' : '✎ Override & Submit'}
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </>
                    ) : (
                        <div className="flex flex-col items-center justify-center min-h-[500px] bg-white rounded-xl border-2 border-dashed border-gray-200">
                            <svg className="w-16 h-16 text-gray-200 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
                            <p className="text-gray-400 text-sm">Select a rental case to begin review</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
