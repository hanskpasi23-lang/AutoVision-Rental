'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import VerificationModal from '@/components/admin/VerificationModal';

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

export default function UsersPage() {
    const { token } = useAuth();
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);
    const [isModalOpen, setIsModalOpen] = useState(false);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    const fetchUsers = async () => {
        if (!token) return;
        try {
            const response = await fetch(`${API_URL}/users/`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            if (response.ok) {
                const data = await response.json();
                setUsers(data);
            }
        } catch (error) {
            console.error('Failed to fetch users', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, [token, API_URL]);

    const toggleUserStatus = async (userId: number, currentStatus: boolean) => {
        try {
            const response = await fetch(`${API_URL}/users/${userId}/toggle-status`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ is_active: !currentStatus }),
            });
            if (response.ok) {
                setUsers(users.map(u =>
                    u.id === userId ? { ...u, is_active: !currentStatus } : u
                ));
            }
        } catch (error) {
            console.error('Failed to toggle user status', error);
        }
    };

    const updateUserRole = async (userId: number, newRole: string) => {
        try {
            const response = await fetch(`${API_URL}/users/${userId}/role`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ role: newRole }),
            });
            if (response.ok) {
                setUsers(users.map(u =>
                    u.id === userId ? { ...u, role: newRole } : u
                ));
            }
        } catch (error) {
            console.error('Failed to update user role', error);
        }
    };

    const getCreditScoreColor = (score: number) => {
        if (score >= 80) return 'text-green-600';
        if (score >= 60) return 'text-yellow-600';
        return 'text-red-600';
    };

    const getVerificationBadge = (status: string) => {
        switch (status) {
            case 'verified':
                return <span className="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">Verified</span>;
            case 'pending':
                return <span className="px-2 py-1 rounded-full text-xs bg-yellow-100 text-yellow-800">Pending Review</span>;
            case 'rejected':
                return <span className="px-2 py-1 rounded-full text-xs bg-red-100 text-red-800">Rejected</span>;
            default:
                return <span className="px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-800">Unverified</span>;
        }
    };

    return (
        <div className="p-6">
            <h1 className="text-2xl font-bold mb-6">User Management</h1>

            <div className="bg-white rounded-lg shadow-md overflow-hidden">
                <table className="w-full text-sm text-left">
                    <thead className="bg-gray-50 text-gray-700 uppercase text-xs">
                        <tr>
                            <th className="px-6 py-3">ID</th>
                            <th className="px-6 py-3">Name</th>
                            <th className="px-6 py-3">Email</th>
                            <th className="px-6 py-3">Role</th>
                            <th className="px-6 py-3">Credit Score</th>
                            <th className="px-6 py-3">Account Status</th>
                            <th className="px-6 py-3">Verification</th>
                            <th className="px-6 py-3">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr>
                                <td colSpan={8} className="px-6 py-8 text-center">
                                    <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500 mx-auto"></div>
                                </td>
                            </tr>
                        ) : users.length === 0 ? (
                            <tr>
                                <td colSpan={8} className="px-6 py-8 text-center text-gray-500">
                                    No users found.
                                </td>
                            </tr>
                        ) : (
                            users.map((user) => (
                                <tr key={user.id} className="border-b hover:bg-gray-50">
                                    <td className="px-6 py-4">{user.id}</td>
                                    <td className="px-6 py-4 font-medium">{user.full_name || '-'}</td>
                                    <td className="px-6 py-4">{user.email}</td>
                                    <td className="px-6 py-4">
                                        <select
                                            value={user.role}
                                            onChange={(e) => updateUserRole(user.id, e.target.value)}
                                            className="bg-gray-50 border border-gray-300 rounded px-2 py-1 text-sm"
                                        >
                                            <option value="user">User</option>
                                            <option value="admin">Admin</option>
                                        </select>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`font-semibold ${getCreditScoreColor(user.credit_score)}`}>
                                            {user.credit_score.toFixed(1)}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 rounded-full text-xs ${user.is_active
                                            ? 'bg-green-100 text-green-800'
                                            : 'bg-red-100 text-red-800'
                                            }`}>
                                            {user.is_active ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        {getVerificationBadge(user.verification_status)}
                                    </td>
                                    <td className="px-6 py-4 flex gap-2">
                                        {}
                                        <button
                                            onClick={() => {
                                                setSelectedUser(user);
                                                setIsModalOpen(true);
                                            }}
                                            className="text-gray-500 hover:text-blue-600 p-1"
                                            title="View Details"
                                        >
                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                            </svg>
                                        </button>

                                        <button
                                            onClick={() => toggleUserStatus(user.id, user.is_active)}
                                            className={`text-sm px-3 py-1 rounded ${user.is_active
                                                ? 'bg-red-100 text-red-600 hover:bg-red-200'
                                                : 'bg-green-100 text-green-600 hover:bg-green-200'
                                                }`}
                                        >
                                            {user.is_active ? 'Suspend' : 'Activate'}
                                        </button>

                                        {user.verification_status === 'pending' && (
                                            <button
                                                onClick={() => {
                                                    setSelectedUser(user);
                                                    setIsModalOpen(true);
                                                }}
                                                className="text-sm px-3 py-1 rounded bg-blue-100 text-blue-600 hover:bg-blue-200"
                                            >
                                                Verify
                                            </button>
                                        )}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {selectedUser && (
                <VerificationModal
                    isOpen={isModalOpen}
                    onClose={() => setIsModalOpen(false)}
                    user={selectedUser}
                    onUpdate={fetchUsers}
                />
            )}
        </div>
    );
}
