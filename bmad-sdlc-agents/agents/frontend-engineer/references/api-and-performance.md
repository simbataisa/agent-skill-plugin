# API Integration & Performance Optimization Guide

> Reference file for the BMAD Frontend Engineer agent.

### 5. API Integration and Data Fetching

**Mandate:** Integrate seamlessly with backend APIs following contracts.

- Review `docs/tech-specs/api-spec.md` for endpoint contracts and authentication
- Use HTTP client library (axios, fetch, SWR, React Query/TanStack Query)
- Implement request/response interceptors for auth tokens and error handling
- Handle all HTTP states: loading, success, error, 401 unauthorized, 403 forbidden
- Implement optimistic updates where appropriate
- Use React Query or SWR for efficient server state management
- Implement proper error boundaries for network failures
- Add retry logic with exponential backoff for transient failures

**API client pattern:**

```tsx
// api/client.ts
import axios, { AxiosError, AxiosInstance } from 'axios';
import { useNavigate } from 'react-router-dom';

export const createApiClient = (navigate?: Function): AxiosInstance => {
  const client = axios.create({
    baseURL: process.env.REACT_APP_API_URL,
    timeout: 10000,
  });

  // Request interceptor: add auth token
  client.interceptors.request.use((config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  // Response interceptor: handle errors
  client.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => {
      if (error.response?.status === 401) {
        // Unauthorized: clear token and redirect to login
        localStorage.removeItem('auth_token');
        navigate?.('/login');
      } else if (error.response?.status === 403) {
        // Forbidden: show error message
        console.error('Access denied');
      }
      return Promise.reject(error);
    }
  );

  return client;
};

// hooks/useUsers.ts
import { useQuery, useMutation } from '@tanstack/react-query';
import { createApiClient } from '../api/client';

interface User {
  id: string;
  name: string;
  email: string;
}

const apiClient = createApiClient();

export const useUsers = () => {
  return useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const response = await apiClient.get<User[]>('/users');
      return response.data;
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
    retry: 2,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
  });
};

export const useCreateUser = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (newUser: Omit<User, 'id'>) => {
      const response = await apiClient.post<User>('/users', newUser);
      return response.data;
    },
    onSuccess: (newUser) => {
      // Update the users list cache
      queryClient.setQueryData(['users'], (oldData: User[] | undefined) => [
        ...(oldData || []),
        newUser,
      ]);
      // Show success notification
      showNotification('User created successfully');
    },
    onError: (error: AxiosError) => {
      showNotification(
        error.response?.data?.message || 'Failed to create user',
        'error'
      );
    },
  });
};

// Component usage
function UsersPage() {
  const { data: users, isLoading, error } = useUsers();
  const { mutate: createUser, isPending } = useCreateUser();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {users?.map((user) => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  );
}
```

### 6. Performance Optimization

**Mandate:** Deliver fast, responsive interfaces that delight users.

- Use Chrome DevTools Lighthouse to measure performance (target: >90 score)
- Implement code splitting: split by route and feature
- Lazy-load images and components using `React.lazy()` and `IntersectionObserver`
- Memoize expensive computations: `useMemo`, `useCallback`, `React.memo`
- Monitor bundle size: use tools like `webpack-bundle-analyzer`
- Optimize assets: minify CSS/JS, compress images (WebP format), gzip compression
- Implement virtual scrolling for long lists
- Measure Core Web Vitals: LCP (Largest Contentful Paint), FID (First Input Delay), CLS (Cumulative Layout Shift)

**Performance optimization pattern:**

```tsx
// Code splitting by route
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));

export const App = () => {
  return (
    <Routes>
      <Route
        path="/dashboard"
        element={
          <Suspense fallback={<LoadingSpinner />}>
            <Dashboard />
          </Suspense>
        }
      />
      <Route
        path="/settings"
        element={
          <Suspense fallback={<LoadingSpinner />}>
            <Settings />
          </Suspense>
        }
      />
    </Routes>
  );
};

// Image lazy loading
const LazyImage: React.FC<{ src: string; alt: string }> = ({ src, alt }) => {
  const [imageSrc, setImageSrc] = useState<string | null>(null);
  const imgRef = useRef<HTMLImageElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && imgRef.current) {
        setImageSrc(src);
        observer.unobserve(entry.target);
      }
    });

    if (imgRef.current) {
      observer.observe(imgRef.current);
    }

    return () => observer.disconnect();
  }, [src]);

  return (
    <img
      ref={imgRef}
      src={imageSrc || 'placeholder.png'}
      alt={alt}
      loading="lazy"
    />
  );
};

// Memoization for expensive computations
const UserList = React.memo(({ users, filter }: UserListProps) => {
  const filteredUsers = useMemo(
    () => users.filter((u) => u.name.includes(filter)),
    [users, filter]
  );

  const handleSort = useCallback((field: string) => {
    // Sorting logic
  }, []);

  return (
    <div>
      {filteredUsers.map((user) => (
        <UserCard key={user.id} user={user} onSort={handleSort} />
      ))}
    </div>
  );
});

// Virtual scrolling for large lists
import { FixedSizeList } from 'react-window';

const LargeList = ({ items }: { items: Item[] }) => {
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      <UserCard user={items[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
};
```

**Performance checklist:**
- [ ] Lighthouse score >90 on all pages
- [ ] Bundle size <250KB (gzipped)
- [ ] Code split by route
- [ ] Images optimized (WebP, correct sizes)
- [ ] No unnecessary re-renders (React DevTools Profiler)
- [ ] Core Web Vitals pass (LCP <2.5s, FID <100ms, CLS <0.1)
- [ ] Network requests optimized (debounced, batched)
- [ ] Caching strategy implemented

