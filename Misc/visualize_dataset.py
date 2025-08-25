import os
import glob
import json
import pickle
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import argparse

def find_files(folder, exts=('.pkl', '.pickle', '.json', '.p')):
    files = []
    for ext in exts:
        files.extend(glob.glob(os.path.join(folder, f'**/*{ext}'), recursive=True))
    return sorted(files)

def load_file(path):
    ext = os.path.splitext(path)[1].lower()
    try:
        if ext == '.json':
            with open(path, 'r') as f:
                obj = json.load(f)
        else:
            with open(path, 'rb') as f:
                obj = pickle.load(f)
    except Exception as e:
        print(f"Warning: failed to load {path}: {e}")
        return [], []
    # try common structures
    if isinstance(obj, dict):
        data = obj.get('data') or obj.get('X') or obj.get('features') or []
        labels = obj.get('labels') or obj.get('y') or obj.get('labels_list') or []
        # if wrapping a sklearn model
        if data is None and 'model' in obj:
            return [], []
        return data or [], labels or []
    # array-like top-level
    return [], []

def load_dataset(folder, max_samples=None):
    files = find_files(folder)
    X_list, y_list = [], []
    for fpath in files:
        data, labels = load_file(fpath)
        if len(data) != len(labels):
            # try flatten if labels absent but data is list of (feat,label) tuples
            if all(isinstance(x, (list, tuple)) and len(x) == 2 for x in data):
                for feat, lab in data:
                    X_list.append(feat)
                    y_list.append(lab)
                continue
            print(f"Skipping {fpath} (inconsistent lengths)")
            continue
        for feat, lab in zip(data, labels):
            X_list.append(np.asarray(feat, dtype=float))
            y_list.append(str(lab))
            if max_samples and len(X_list) >= max_samples:
                break
        if max_samples and len(X_list) >= max_samples:
            break
    if not X_list:
        raise RuntimeError(f"No valid data found in {folder}")
    # pad/trim inconsistent feature lengths (make 2D array)
    max_len = max(len(x) for x in X_list)
    X = np.array([np.pad(x, (0, max_len - len(x)), 'constant', constant_values=0) for x in X_list])
    y = np.array(y_list)
    return X, y

def plot_pca_scatter(X, y, title="Dataset PCA (2D)", save_path=None, figsize=(10,8), label_point=False):
    scaler = StandardScaler()
    Xs = scaler.fit_transform(X)
    pca = PCA(n_components=2)
    Z = pca.fit_transform(Xs)
    classes, counts = np.unique(y, return_counts=True)
    cmap = plt.get_cmap('tab20')
    color_map = {cls: cmap(i % 20) for i, cls in enumerate(classes)}

    # Create a new figure (one per category) and set window title so OS opens separate windows
    fig = plt.figure(figsize=figsize)
    ax = fig.add_subplot(111)
    try:
        fig.canvas.manager.set_window_title(title)
    except Exception:
        # some backends do not support setting window title
        pass

    for cls in classes:
        idx = (y == cls)
        ax.scatter(Z[idx,0], Z[idx,1], label=f"{cls} ({idx.sum()})", alpha=0.7, c=[color_map[cls]])
    ax.set_title(title + f"  — explained {pca.explained_variance_ratio_.sum():.2f}")
    ax.set_xlabel("PC1")
    ax.set_ylabel("PC2")
    ax.legend(loc='best', fontsize='small', ncol=2)
    ax.grid(alpha=0.2)
    if label_point:
        for i, txt in enumerate(y):
            ax.annotate(txt, (Z[i,0], Z[i,1]), fontsize=6, alpha=0.6)

    if save_path:
        fig.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved PCA scatter to {save_path}")

    # Return the figure so caller can decide when to show (caller will call plt.show() once)
    return fig

def plot_feature_histograms(X, y, features=None, top_n=6, save_path=None):
    # features: list of indices; if None use first top_n
    n_features = X.shape[1]
    if features is None:
        features = list(range(min(top_n, n_features)))
    n_plots = len(features)
    cols = min(3, n_plots)
    rows = (n_plots + cols - 1) // cols
    plt.figure(figsize=(4*cols, 3*rows))
    classes = np.unique(y)
    for i, fi in enumerate(features, 1):
        plt.subplot(rows, cols, i)
        for cls in classes:
            vals = X[y==cls, fi]
            if len(vals):
                plt.hist(vals, bins=30, alpha=0.5, label=f"{cls} ({len(vals)})")
        plt.title(f"Feature #{fi}")
        plt.legend(fontsize='x-small')
    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches='tight')
        print(f"Saved histograms to {save_path}")
    else:
        plt.show()

# new helper: load and normalize X,y from a single file path (reuses load_file behavior)
def get_X_y_from_file(fpath, max_samples=None):
    data, labels = load_file(fpath)
    # handle list-of-(feat,label) packed in 'data'
    if (not labels) and data and all(isinstance(x, (list, tuple)) and len(x) == 2 for x in data):
        X_list, y_list = [], []
        for feat, lab in data:
            X_list.append(np.asarray(feat, dtype=float))
            y_list.append(str(lab))
        if not X_list:
            return None, None
        max_len = max(len(x) for x in X_list)
        X = np.array([np.pad(x, (0, max_len - len(x)), 'constant', constant_values=0) for x in X_list])
        y = np.array(y_list)
        return X, y

    # expected explicit labels list
    if not data or not labels or len(data) != len(labels):
        return None, None
    X_list = [np.asarray(x, dtype=float) for x in data]
    max_len = max(len(x) for x in X_list)
    X = np.array([np.pad(x, (0, max_len - len(x)), 'constant', constant_values=0) for x in X_list])
    y = np.array([str(l) for l in labels])
    return X, y

# new GUI main: file list + per-file checkboxes
def main_gui(folder):
    try:
        import tkinter as tk
        from tkinter import ttk, messagebox
    except Exception as e:
        raise SystemExit("Tkinter not available: cannot start GUI")

    files = find_files(folder)
    if not files:
        raise SystemExit(f"No data files (.pkl/.p/.json) found in {folder}")

    root = tk.Tk()
    root.title("Visualize dataset — select file and classes")

    # Left: file list
    left_frame = ttk.Frame(root, padding=8)
    left_frame.grid(row=0, column=0, sticky="ns")
    ttk.Label(left_frame, text="Data files:").pack(anchor="w")
    file_listbox = tk.Listbox(left_frame, height=12, width=40)
    file_listbox.pack(side="left", fill="y")
    scrollbar = ttk.Scrollbar(left_frame, orient="vertical", command=file_listbox.yview)
    scrollbar.pack(side="right", fill="y")
    file_listbox.config(yscrollcommand=scrollbar.set)
    for f in files:
        file_listbox.insert("end", os.path.basename(f))

    # Right: checkboxes area
    right_frame = ttk.Frame(root, padding=8)
    right_frame.grid(row=0, column=1, sticky="nsew")
    ttk.Label(right_frame, text="Classes (tick to include):").pack(anchor="w")
    cb_canvas = tk.Canvas(right_frame)
    cb_scroll = ttk.Scrollbar(right_frame, orient="vertical", command=cb_canvas.yview)
    cb_frame = ttk.Frame(cb_canvas)
    cb_frame_id = cb_canvas.create_window((0,0), window=cb_frame, anchor="nw")
    cb_canvas.configure(yscrollcommand=cb_scroll.set, width=320, height=300)
    cb_canvas.pack(side="left", fill="both", expand=True)
    cb_scroll.pack(side="right", fill="y")

    def on_frame_config(event):
        cb_canvas.configure(scrollregion=cb_canvas.bbox("all"))
    cb_frame.bind("<Configure>", on_frame_config)

    # store checkbox variables
    checkbox_vars = {}
    current_file_path = {"path": None}

    def load_selected_file(event=None):
        idx = file_listbox.curselection()
        if not idx:
            return
        fname = file_listbox.get(idx[0])
        # full path
        for f in files:
            if os.path.basename(f) == fname:
                fpath = f
                break
        else:
            messagebox.showerror("Error", "File not found")
            return

        X, y = get_X_y_from_file(fpath, max_samples=None)
        if X is None:
            messagebox.showerror("Error", f"No valid data in {fname}")
            return

        # clear previous checkboxes
        for widget in cb_frame.winfo_children():
            widget.destroy()
        checkbox_vars.clear()

        classes = sorted(np.unique(y))
        for cls in classes:
            var = tk.BooleanVar(value=True)
            cb = ttk.Checkbutton(cb_frame, text=f"{cls} ({sum(y==cls)})", variable=var)
            cb.pack(anchor="w", pady=1)
            checkbox_vars[cls] = var

        current_file_path["path"] = fpath

    file_listbox.bind("<<ListboxSelect>>", load_selected_file)

    # Buttons
    btn_frame = ttk.Frame(root, padding=8)
    btn_frame.grid(row=1, column=0, columnspan=2, sticky="ew")
    def plot_selected_pca():
        fpath = current_file_path["path"]
        if not fpath:
            messagebox.showinfo("Info", "Select a file first")
            return
        X, y = get_X_y_from_file(fpath)
        if X is None:
            messagebox.showerror("Error", "Cannot load data for selected file")
            return
        selected = [cls for cls, var in checkbox_vars.items() if var.get()]
        if not selected:
            messagebox.showinfo("Info", "No classes selected")
            return
        mask = np.isin(y, selected)
        if not mask.any():
            messagebox.showinfo("Info", "No samples for selected classes")
            return
        Xf = X[mask]
        yf = y[mask]
        plot_pca_scatter(Xf, yf, title=os.path.splitext(os.path.basename(fpath))[0])
        plt.show()

    def plot_selected_hist():
        fpath = current_file_path["path"]
        if not fpath:
            messagebox.showinfo("Info", "Select a file first")
            return
        X, y = get_X_y_from_file(fpath)
        if X is None:
            messagebox.showerror("Error", "Cannot load data for selected file")
            return
        selected = [cls for cls, var in checkbox_vars.items() if var.get()]
        if not selected:
            messagebox.showinfo("Info", "No classes selected")
            return
        mask = np.isin(y, selected)
        if not mask.any():
            messagebox.showinfo("Info", "No samples for selected classes")
            return
        Xf = X[mask]
        yf = y[mask]
        plot_feature_histograms(Xf, yf, top_n=6)
        plt.show()

    ttk.Button(btn_frame, text="Plot PCA (selected classes)", command=plot_selected_pca).pack(side="left", padx=6)
    ttk.Button(btn_frame, text="Plot Hist (selected classes)", command=plot_selected_hist).pack(side="left", padx=6)
    def plot_all_files():
        for fpath in files:
            X, y = get_X_y_from_file(fpath)
            if X is None:
                continue
            plot_pca_scatter(X, y, title=os.path.splitext(os.path.basename(fpath))[0])
        plt.show()
    ttk.Button(btn_frame, text="Plot All Files (all classes)", command=plot_all_files).pack(side="left", padx=6)

    # Select first file automatically
    if files:
        file_listbox.selection_set(0)
        load_selected_file()

    root.mainloop()

# replace main with GUI entry, keep CLI fallback
def main():
    parser = argparse.ArgumentParser(description="Visualize extracted features from dataset folder (PCA 2D scatter)")
    parser.add_argument("folder", nargs='?', default="MP_DATA", help="Dataset folder to scan (default Dataset)")
    parser.add_argument("--nogui", action='store_true', help="Run in CLI mode (no GUI)")
    parser.add_argument("--max", type=int, default=None, help="Max samples to load (CLI only)")
    parser.add_argument("--save", type=str, default=None, help="Save base filename for outputs (CLI only)")
    parser.add_argument("--hist", action='store_true', help="Also plot feature histograms (CLI only)")
    parser.add_argument("--label_points", action='store_true', help="Annotate each point with its class label (CLI only)")
    args = parser.parse_args()

    folder = args.folder
    if not os.path.isdir(folder):
        raise SystemExit(f"Folder not found: {folder}")

    if args.nogui:
        # fallback to previous CLI behavior: create one window per file
        files = find_files(folder)
        if not files:
            raise SystemExit(f"No data files (.pkl/.p/.json) found in {folder}")
        figs = []
        for fpath in files:
            X, y = get_X_y_from_file(fpath, max_samples=args.max)
            if X is None:
                print(f"Skipping {fpath}: no valid data")
                continue
            file_label = os.path.splitext(os.path.basename(fpath))[0]
            fig = plot_pca_scatter(X, y, title=f"{file_label}", save_path=None, label_point=args.label_points)
            figs.append(fig)
            if args.hist:
                plot_feature_histograms(X, y, top_n=6, save_path=None)
        if not figs:
            raise SystemExit("No plots created (no valid data).")
        plt.show()
    else:
        main_gui(folder)

if __name__ == "__main__":
    main()
