import { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';

interface Document {
    id: number;
    document_type: string;
    image_url: string;
    created_at: string;
}

interface User {
    id: number;
    email: string;
    full_name: string | null;
    role: string;
    is_active: boolean;
    credit_score: number;
    created_at: string;
    verification_status: string;
}

interface VerificationModalProps {
    isOpen: boolean;
    onClose: () => void;
    user: User;
    onUpdate: () => void;
}

export default function VerificationModal({ isOpen, onClose, user, onUpdate }: VerificationModalProps) {
    const { token } = useAuth();
    const [documents, setDocuments] = useState<Document[]>([]);
    const [loading, setLoading] = useState(false);
    const [actionLoading, setActionLoading] = useState(false);
    const [notes, setNotes] = useState('');
    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {
        if (isOpen && user?.id) {
            fetchDocuments();
            setNotes('');
        }
    }, [isOpen, user]);

    const fetchDocuments = async () => {
        setLoading(true);
        try {
            const response = await fetch(`${API_URL}/users/admin/${user.id}/verification`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            if (response.ok) {
                const data = await response.json();
                setDocuments(data);
            }
        } catch (error) {
            console.error('Failed to fetch documents', error);
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async (status: 'verified' | 'rejected') => {
        if (status === 'rejected' && !notes) {
            alert('Please provide a reason for rejection.');
            return;
        }

        setActionLoading(true);
        try {
            const response = await fetch(`${API_URL}/users/admin/${user.id}/verify`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    verification_status: status,
                    verification_notes: notes,
                }),
            });

            if (response.ok) {
                onUpdate();
                onClose();
            } else {
                alert('Failed to update verification status.');
            }
        } catch (error) {
            console.error('Failed to verify user', error);
        } finally {
            setActionLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg w-full max-w-4xl max-h-[90vh] overflow-y-auto">
                <div className="p-6 border-b flex justify-between items-center">
                    <h2 className="text-xl font-bold">User Details: {user.full_name || user.email}</h2>
                    <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <div className="p-6">
                    {}
                    <div className="mb-8 grid grid-cols-1 md:grid-cols-2 gap-4 bg-gray-50 p-4 rounded-lg">
                        <div>
                            <p className="text-sm text-gray-500">Email</p>
                            <p className="font-medium">{user.email}</p>
                        </div>
                        <div>
                            <p className="text-sm text-gray-500">Role</p>
                            <p className="font-medium capitalize">{user.role}</p>
                        </div>
                        <div>
                            <p className="text-sm text-gray-500">Account Status</p>
                            <p className={`font-medium ${user.is_active ? 'text-green-600' : 'text-red-600'}`}>
                                {user.is_active ? 'Active' : 'Inactive'}
                            </p>
                        </div>
                        <div>
                            <p className="text-sm text-gray-500">Credit Score</p>
                            <p className="font-medium">{user.credit_score.toFixed(1)}</p>
                        </div>
                        <div>
                            <p className="text-sm text-gray-500">Verification Status</p>
                            <p className={`font-medium capitalize ${user.verification_status === 'verified' ? 'text-green-600' :
                                    user.verification_status === 'rejected' ? 'text-red-600' :
                                        user.verification_status === 'pending' ? 'text-yellow-600' : 'text-gray-600'
                                }`}>{user.verification_status}</p>
                        </div>
                        <div>
                            <p className="text-sm text-gray-500">Member Since</p>
                            <p className="font-medium">{new Date(user.created_at).toLocaleDateString()}</p>
                        </div>
                    </div>

                    <h3 className="text-lg font-semibold mb-4">Verification Documents</h3>

                    {loading ? (
                        <div className="flex justify-center p-8">
                            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                        </div>
                    ) : documents.length === 0 ? (
                        <div className="text-center p-8 text-gray-500 border rounded-lg bg-gray-50">
                            No documents uploaded by this user.
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                            {documents.map((doc) => (
                                <div key={doc.id} className="border rounded-lg p-2">
                                    <p className="font-semibold mb-2 capitalize">{doc.document_type.replace('_', ' ')}</p>
                                    <img
                                        src={`${API_URL}${doc.image_url}`}
                                        alt={doc.document_type}
                                        className="w-full h-48 object-cover rounded cursor-pointer hover:opacity-90"
                                        onClick={() => window.open(`${API_URL}${doc.image_url}`, '_blank')}
                                    />
                                    <p className="text-xs text-gray-500 mt-1">Uploaded: {new Date(doc.created_at).toLocaleDateString()}</p>
                                </div>
                            ))}
                        </div>
                    )}

                    {}
                    {user.verification_status === 'pending' && (
                        <div className="mt-6 border-t pt-6">
                            <h3 className="text-lg font-semibold mb-4">Review Action</h3>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Admin Notes (Required for rejection)
                            </label>
                            <textarea
                                className="w-full border rounded-md p-2 mb-4"
                                rows={3}
                                placeholder="Enter reason for rejection or approval notes..."
                                value={notes}
                                onChange={(e) => setNotes(e.target.value)}
                            />

                            <div className="flex justify-end space-x-4">
                                <button
                                    onClick={() => handleVerify('rejected')}
                                    disabled={actionLoading}
                                    className="px-4 py-2 bg-red-100 text-red-700 rounded hover:bg-red-200 disabled:opacity-50"
                                >
                                    {actionLoading ? 'Processing...' : 'Reject Application'}
                                </button>
                                <button
                                    onClick={() => handleVerify('verified')}
                                    disabled={actionLoading}
                                    className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                                >
                                    {actionLoading ? 'Processing...' : 'Approve & Verify'}
                                </button>
                            </div>
                        </div>
                    )}

                    {}
                    {user.verification_status !== 'pending' && (
                        <div className="mt-6 border-t pt-6 flex justify-end">
                            <button
                                onClick={onClose}
                                className="px-4 py-2 bg-gray-100 text-gray-700 rounded hover:bg-gray-200"
                            >
                                Close
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
