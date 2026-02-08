/**
 * ProfileSettingsModal Component
 *
 * Modal for editing user profile settings:
 * - Name (editable)
 * - Email (display only - can't change)
 * - Password change section
 */

'use client';

import { useRef, useState, useEffect, memo } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';

interface ProfileSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  user?: {
    name: string;
    email: string;
  };
}

function ProfileSettingsModalComponent({ isOpen, onClose, user }: ProfileSettingsModalProps) {
  // Use refs for uncontrolled inputs - no re-render on typing
  const nameRef = useRef<HTMLInputElement>(null);
  const currentPasswordRef = useRef<HTMLInputElement>(null);
  const newPasswordRef = useRef<HTMLInputElement>(null);
  const confirmPasswordRef = useRef<HTMLInputElement>(null);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // DEBUG: Track component lifecycle
  useEffect(() => {
    console.log('🔵 ProfileSettingsModal MOUNTED');
    return () => {
      console.log('🔴 ProfileSettingsModal UNMOUNTED');
    };
  }, []);

  // DEBUG: Track re-renders
  useEffect(() => {
    console.log('🔄 ProfileSettingsModal RE-RENDERED', { isOpen, userName: user?.name });
  });

  // Reset form when modal opens
  useEffect(() => {
    if (isOpen) {
      console.log('✅ Modal opened, resetting form');
      if (nameRef.current) nameRef.current.value = user?.name || '';
      if (currentPasswordRef.current) currentPasswordRef.current.value = '';
      if (newPasswordRef.current) newPasswordRef.current.value = '';
      if (confirmPasswordRef.current) confirmPasswordRef.current.value = '';
      setError('');
    }
  }, [isOpen, user?.name]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Get values from refs (uncontrolled inputs)
    const nameValue = nameRef.current?.value || '';
    const currentPasswordValue = currentPasswordRef.current?.value || '';
    const newPasswordValue = newPasswordRef.current?.value || '';
    const confirmPasswordValue = confirmPasswordRef.current?.value || '';

    // Validate password change if attempted
    if (newPasswordValue || confirmPasswordValue || currentPasswordValue) {
      if (!currentPasswordValue) {
        setError('Current password is required to change password');
        return;
      }
      if (newPasswordValue !== confirmPasswordValue) {
        setError('New passwords do not match');
        return;
      }
      if (newPasswordValue.length < 8) {
        setError('New password must be at least 8 characters');
        return;
      }
    }

    setIsLoading(true);

    try {
      // TODO: Implement API call to update profile
      console.log('Updating profile:', {
        name: nameValue,
        currentPassword: currentPasswordValue,
        newPassword: newPasswordValue
      });

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Success - close modal
      onClose();
    } catch (err) {
      setError('Failed to update profile. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleClose = () => {
    // Clear form refs
    if (nameRef.current) nameRef.current.value = user?.name || '';
    if (currentPasswordRef.current) currentPasswordRef.current.value = '';
    if (newPasswordRef.current) newPasswordRef.current.value = '';
    if (confirmPasswordRef.current) confirmPasswordRef.current.value = '';
    setError('');
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="Profile Settings">
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Error Message */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-300 rounded-lg text-sm text-red-700 dark:bg-red-900/20 dark:border-red-800 dark:text-red-400">
            {error}
          </div>
        )}

        {/* Basic Info Section */}
        <div className="space-y-4">
          <h3 className="text-heading-md font-semibold text-text-primary">Basic Information</h3>

          <Input
            ref={nameRef}
            label="Name"
            defaultValue={user?.name || ''}
            placeholder="Enter your name"
            required
          />

          <Input
            label="Email"
            value={user?.email || ''}
            disabled
            helperText="Email cannot be changed"
          />
        </div>

        {/* Password Change Section */}
        <div className="pt-4 border-t border-border-subtle space-y-4">
          <h3 className="text-heading-md font-semibold text-text-primary">Change Password</h3>
          <p className="text-sm text-text-secondary">Leave blank to keep current password</p>

          <Input
            ref={currentPasswordRef}
            label="Current Password"
            type="password"
            placeholder="Enter current password"
          />

          <Input
            ref={newPasswordRef}
            label="New Password"
            type="password"
            placeholder="Enter new password"
            helperText="Minimum 8 characters"
          />

          <Input
            ref={confirmPasswordRef}
            label="Confirm New Password"
            type="password"
            placeholder="Confirm new password"
          />
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-3 pt-4">
          <Button
            type="button"
            variant="secondary"
            onClick={handleClose}
            disabled={isLoading}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            isLoading={isLoading}
          >
            Save Changes
          </Button>
        </div>
      </form>
    </Modal>
  );
}

// Export memoized version to prevent unnecessary re-renders
export const ProfileSettingsModal = memo(ProfileSettingsModalComponent);
