'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface User {
    id: number;
    email: string;
    full_name: string | null;
    role: string;
    credit_score: number;
}

interface AuthContextType {
    user: User | null;
    token: string | null;
    isLoading: boolean;
    login: (email: string, password: string) => Promise<{ success: boolean; isAdmin?: boolean }>;
    logout: () => void;
    isAuthenticated: boolean;
    isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

    useEffect(() => {

        const storedToken = localStorage.getItem('token');
        if (storedToken) {
            setToken(storedToken);
            fetchUser(storedToken);
        } else {
            setIsLoading(false);
        }
    }, []);

    const fetchUser = React.useCallback(async (authToken: string) => {
        try {
            const response = await fetch(`${API_URL}/users/me`, {
                headers: {
                    'Authorization': `Bearer ${authToken}`,
                },
            });
            if (response.ok) {
                const userData = await response.json();
                setUser(userData);
            } else {

                localStorage.removeItem('token');
                setToken(null);
            }
        } catch (error) {
            console.error('Error fetching user:', error);
        } finally {
            setIsLoading(false);
        }
    }, [API_URL]);

    const login = async (email: string, password: string): Promise<{ success: boolean; isAdmin?: boolean }> => {
        try {
            const response = await fetch(`${API_URL}/users/token`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password }),
            });

            if (response.ok) {
                const data = await response.json();
                localStorage.setItem('token', data.access_token);
                setToken(data.access_token);

                const userResponse = await fetch(`${API_URL}/users/me`, {
                    headers: { 'Authorization': `Bearer ${data.access_token}` },
                });

                if (userResponse.ok) {
                    const userData = await userResponse.json();
                    setUser(userData);
                    return { success: true, isAdmin: userData.role === 'admin' };
                }
                return { success: true, isAdmin: false };
            }
            return { success: false };
        } catch (error) {
            console.error('Login error:', error);
            return { success: false };
        }
    };

    const logout = () => {
        localStorage.removeItem('token');
        setToken(null);
        setUser(null);
    };

    return (
        <AuthContext.Provider
            value={{
                user,
                token,
                isLoading,
                login,
                logout,
                isAuthenticated: !!user,
                isAdmin: user?.role === 'admin',
            }}
        >
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
}
