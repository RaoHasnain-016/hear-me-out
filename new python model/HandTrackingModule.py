import cv2
import mediapipe as mp


class handDetector:
    def __init__(self, mode=False, maxHands=2, detectionCon=0.5, trackCon=0.5):
        self.mode = mode
        self.maxHands = maxHands
        self.detectionCon = detectionCon
        self.trackCon = trackCon

        self.mpHands = mp.solutions.hands
        self.hands = self.mpHands.Hands(
            static_image_mode=self.mode,
            max_num_hands=self.maxHands,
            min_detection_confidence=self.detectionCon,
            min_tracking_confidence=self.trackCon
        )
        self.mpDraw = mp.solutions.drawing_utils
        self.result = None

    def findHands(self, img, draw=True):
        try:
            imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            self.result = self.hands.process(imgRGB)

            if self.result.multi_hand_landmarks and draw:
                for handLand in self.result.multi_hand_landmarks:
                    self.mpDraw.draw_landmarks(
                        img,
                        handLand,
                        self.mpHands.HAND_CONNECTIONS
                    )
        except Exception:
            self.result = None

        return img

    def findPosition(self, img, handNo=0, draw=True):
        posList = []

        try:
            if not self.result or not self.result.multi_hand_landmarks:
                return posList

            if handNo < 0 or handNo >= len(self.result.multi_hand_landmarks):
                return posList

            myHand = self.result.multi_hand_landmarks[handNo]
            h, w, _ = img.shape

            for landmark_id, lm in enumerate(myHand.landmark):
                cx, cy = int(lm.x * w), int(lm.y * h)
                posList.append([landmark_id, cx, cy])

                if draw:
                    cv2.circle(img, (cx, cy), 5, (255, 0, 0), cv2.FILLED)
        except Exception:
            return []

        return posList
