# Details
 * Amuse is a hand-gesture controlled Apple Music player that uses Music Kit (Application Music Player) and Gesture Kit. The app utilizes 4 gestures to control music playback:
<h2>Gesture Controls</h2>

<table>
  <thead>
    <tr>
      <th align="left">Gesture</th>
      <th align="left">Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>✌️ Peace Sign</td>
      <td>
        Pauses and plays the current track added to the queue
        <br /><br />
        <img
          src="https://github.com/user-attachments/assets/b90d3e57-3d11-49e1-b5f0-07c796d34820"
          width="160"
          alt="Peace Sign Gesture"
        />
      </td>
    </tr>
    <tr>
      <td>✊ Left Fist</td>
      <td>
        Opens the Immersive View of Songs and their respective album covers
        <br /><br />
        <img
          src="https://github.com/user-attachments/assets/26c61734-807c-4a2d-881a-3f2d25b71d55"
          width="160"
          alt="Left Fist Gesture"
        />
      </td>
    </tr>
    <tr>
      <td>👈 Left Thumb + Middle Finger Click</td>
      <td>
        Skips to the previous track
        <br /><br />
        <img
          src="https://github.com/user-attachments/assets/fedcebf6-8b83-4a03-ab07-cb82f8893d68"
          width="160"
          alt="Previous Track Gesture"
        />
      </td>
    </tr>
    <tr>
      <td>👉 Right Thumb + Ring Finger Click</td>
      <td>
        Skips to the next track
        <br /><br />
        <img
          src="https://github.com/user-attachments/assets/e85f6583-2e66-4c27-9c3d-c58e49d916ca"
          width="160"
          alt="Next Track Gesture"
        />
      </td>
    </tr>
  </tbody>
</table>

# Setup

 * For each of the .gesturecomposer files in this repository, please ensure **Build Rules are set to Apply once to Folder and the project is set as a target** as seen in this screenshot:

   <img width="253" height="255" alt="image" src="https://github.com/user-attachments/assets/fc4037c6-a1b5-4a26-a53e-4c0ce5baeb6f" />

   * this can be configured by pressing cmd + option + 1
 * You should see the folders in Project Build Phases -> Copy Bundle Resources:
<img width="507" height="172" alt="image" src="https://github.com/user-attachments/assets/d3d0e4f1-6ed3-482e-99fb-56def3a8f3fb" />

 
 * Additionally, please ensure GestureKit as well as MusicKit are added as package dependencies in your Xcode project.



## Enable MusicKit for your App ID
The following steps are <span style="color:red">REQUIRED</span> to use MusicKit: 

* In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources), click Identifiers in the sidebar.

* On the top left, click the add button (+), select App IDs, then click Continue.

* [Register an App ID](https://developer.apple.com/help/account/manage-identifiers/register-an-app-id).

* Click the App Services tab.

* Select the MusicKit checkbox.

* Click Continue, review the registration information, and click Register.

***Source**: [developer.apple.com](https://developer.apple.com/help/account/configure-app-services/musickit/)*



## Video Preview
Here's an early stage demo of the hand gestures in action:[▶ Watch Demo](amuse_gestures.mp4)

https://github.com/user-attachments/assets/b9d1fde4-fe8e-49c0-8f96-d52fdcda59e7

Big Thanks to @IvanCampos for the MusicKit boilerplate code

