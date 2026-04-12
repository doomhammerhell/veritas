import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

// Mock get-starknet since it requires browser wallet
jest.mock('get-starknet', () => ({
  connect: jest.fn(),
  disconnect: jest.fn(),
}));

test('renders Veritas heading', () => {
  render(<App />);
  expect(screen.getByText('Veritas')).toBeInTheDocument();
});

test('renders Connect Wallet button when not connected', () => {
  render(<App />);
  expect(screen.getByText('Connect Wallet')).toBeInTheDocument();
});

test('renders phase info cards', () => {
  render(<App />);
  expect(screen.getByText('Phase')).toBeInTheDocument();
  expect(screen.getByText('Options')).toBeInTheDocument();
  expect(screen.getByText('Commits')).toBeInTheDocument();
  expect(screen.getByText('Reveals')).toBeInTheDocument();
});

test('shows contract address warning when not configured', () => {
  render(<App />);
  expect(
    screen.getByText(/Set REACT_APP_CONTRACT_ADDRESS/)
  ).toBeInTheDocument();
});
