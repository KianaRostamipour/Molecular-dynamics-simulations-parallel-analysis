"""
This script has been designed to visualize and analyze data from MD. It processes and plots various metrics such as RMSD and minimum distances over time. The script generates graphs for each metric, showing both the raw data and a moving average to highlight trends.
"""
import numpy as np
import os
import matplotlib.pyplot as plt

def load_data(file_path):
    x_values, y_values = [], []
    with open(file_path, 'r') as file:
        for line in file:
            if not line.startswith(('@', '#')):
                values = line.split()
                x_values.append(float(values[0]))
                y_values.append(float(values[1]))
    return x_values, y_values

def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='valid')

def plot_data(x_values, y_values, title, xlabel, ylabel, output_dir, file_name, average_window=5):
    plt.figure(figsize=(8, 5))
    plt.plot(x_values, y_values, linestyle='-', label='Original Data')
    y_avg = moving_average(y_values, average_window)
    avg_x_values = x_values[len(x_values)-len(y_avg):]
    plt.plot(avg_x_values, y_avg, linestyle='-', color='red', label='Moving Average')
    overall_avg = np.mean(y_values)
    mid_index = len(avg_x_values) // 2
    mid_x = avg_x_values[mid_index]
    mid_y = y_avg[mid_index]
    plt.text(mid_x, mid_y, f'Avg: {overall_avg:.2f}', fontsize=9, backgroundcolor='yellow', 
             verticalalignment='center', horizontalalignment='center')
    
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend(loc='upper left')
    plt.grid(True)
    
    full_file_name = os.path.join(output_dir, file_name)
    plt.savefig(full_file_name)
    plt.close()

base_dir = os.getcwd()
output_dir = os.path.join(base_dir, 'analysis')
os.makedirs(output_dir, exist_ok=True)

mdtot_dir = os.path.join(base_dir, 'analysis')
file_paths = ['mindist_all_segments.xvg', 'numberofcontacts_all_segments.xvg', 'rmsd_all_segments.xvg', 'rmsd_lig_all_segments.xvg']
titles = ['mindist lig-pro', 'Number of contacts lig-pro', 'Protein RMSD', 'Ligand RMSD']
x_labels = ['Time (ns)', 'Time (ns)', 'Time (ns)', 'Time (ns)']
y_labels = ['mindist (nm)', 'Number', 'RMSD (nm)', 'RMSD (nm)']
file_names = ['image3.jpg', 'image4.jpg', 'image1.jpg', 'image2.jpg']

for file_path, title, x_label, y_label, file_name in zip(file_paths, titles, x_labels, y_labels, file_names):
    full_file_path = os.path.join(mdtot_dir, file_path)
    x_values, y_values = load_data(full_file_path)
    plot_data(x_values, y_values, title, x_label, y_label, output_dir, file_name, average_window=50)

