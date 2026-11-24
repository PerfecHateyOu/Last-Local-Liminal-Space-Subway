/**
 * Cutscene Overlay for LAST LOCAL
 * Displays scene title, beat dots, progress bar, and a Skip button (44px touch target).
 * Dialogue subtitles and PA banners reuse HUD.tsx directly so they never drift out of sync.
 */
import React from 'react';
import { FastForward } from 'lucide-react';
import { CutscenePlayer } from '../game/cutscenes';

interface CutsceneOverlayProps {
  cutscene: CutscenePlayer;
  isTouch: boolean;
  onSkip: () => void;
}

export const CutsceneOverlay: React.FC<CutsceneOverlayProps> = ({ cutscene, isTouch, onSkip }) => {
  const pct = Math.round(cutscene.progress * 100);

  return (
    <div
      data-testid="cutscene-overlay"
      className="fixed inset-0 pointer-events-none select-none z-20"
      style={{
        paddingBottom: 'env(safe-area-inset-bottom, 0px)',
        paddingLeft: 'env(safe-area-inset-left, 0px)',
        paddingRight: 'env(safe-area-inset-right, 0px)',
      }}
    >
      {/* Title, beat dots, and progress bar */}
      <div className="absolute left-4 bottom-[max(1.25rem,env(safe-area-inset-bottom))] max-w-[calc(100vw-8.5rem)] sm:max-w-xs px-3.5 py-2 rounded-xl bg-black/70 border border-white/15 shadow-lg">
        <div className="flex items-center justify-between gap-3 mb-1.5">
          <span className="font-mono text-2xs font-bold uppercase tracking-[0.16em] text-cream/90 truncate">
            {cutscene.title}
          </span>
          <div className="flex items-center gap-1 shrink-0" aria-label={`Beat ${cutscene.index + 1} of ${cutscene.beats.length}`}>
            {cutscene.beats.map((_, i) => (
              <span
                key={i}
                className={`rounded-full transition-colors calm:transition-none ${
                  i === cutscene.index
                    ? 'w-2 h-2 bg-g-line'
                    : i < cutscene.index
                    ? 'w-1.5 h-1.5 bg-cream/60'
                    : 'w-1.5 h-1.5 bg-white/20'
                }`}
              />
            ))}
          </div>
        </div>
        <div className="w-full h-1 rounded-full bg-white/15 overflow-hidden">
          <div
            data-testid="cutscene-progress"
            className="h-full bg-g-line transition-[width] duration-75 ease-linear calm:transition-none"
            style={{ width: `${pct}%` }}
          />
        </div>
      </div>

      {/* Skip button (44px+ touch target, bottom-right) */}
      <button
        type="button"
        data-testid="cutscene-skip"
        onClick={onSkip}
        aria-label="Skip cutscene"
        aria-keyshortcuts="Space Enter"
        className="pointer-events-auto absolute right-4 bottom-[max(1.25rem,env(safe-area-inset-bottom))] min-h-11 min-w-11 px-4 rounded-full bg-black/75 hover:bg-black/90 border border-white/25 hover:border-g-line text-cream text-xs sm:text-sm font-bold tracking-wide flex items-center justify-center gap-2 shadow-xl transition-colors active:translate-y-px focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cream"
      >
        <span>Skip</span>
        {!isTouch && (
          <kbd className="hidden sm:inline text-3xs font-mono text-cream/75 bg-white/10 px-1.5 py-0.5 rounded">
            Space
          </kbd>
        )}
        <FastForward className="w-3.5 h-3.5 text-g-line" />
      </button>
    </div>
  );
};
