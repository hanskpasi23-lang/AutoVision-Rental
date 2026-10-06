import { Sidebar } from "@/components/admin/Sidebar";
import { Navbar } from "@/components/admin/Navbar";

const AdminLayout = ({
    children
}: {
    children: React.ReactNode;
}) => {
    return (
        <div className="h-full relative">
            <div className="hidden h-full md:flex md:w-20 md:hover:w-72 md:flex-col md:fixed md:inset-y-0 z-[80] bg-gray-900 transition-all duration-300 ease-in-out group overflow-hidden">
                <Sidebar />
            </div>
            <main className="md:pl-20 transition-all duration-300 ease-in-out">
                <Navbar />
                {children}
            </main>
        </div>
    );
}

export default AdminLayout;
