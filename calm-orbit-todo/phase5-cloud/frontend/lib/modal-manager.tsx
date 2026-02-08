'use client';

import { create } from 'zustand';

interface ModalState {
  isProfileSettingsOpen: boolean;
  openProfileSettings: () => void;
  closeProfileSettings: () => void;
}

export const useModalStore = create<ModalState>((set) => ({
  isProfileSettingsOpen: false,
  openProfileSettings: () => set({ isProfileSettingsOpen: true }),
  closeProfileSettings: () => set({ isProfileSettingsOpen: false }),
}));
